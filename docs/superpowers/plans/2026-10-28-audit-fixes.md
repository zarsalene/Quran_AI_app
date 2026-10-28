# Audit Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the 9 findings of the 2026-10-28 ponytail audit: signing key, speech-engine leaks and load time, spaced-repetition and calendar bugs, a stuck download, and dead code.

**Architecture:** Six tasks, one per area. Task 2 replaces "one speech engine per screen" with "one speech engine per app run". This one change fixes audit findings 2, 3 and 6. The other tasks are small, local fixes with a test each.

**Tech Stack:** Flutter 3.47.7 (Dart), `sherpa_onnx` 1.13.8, `just_audio`, `shared_preferences`, Gradle Kotlin DSL, GitHub Actions.

**Spec:** The audit report in the session of 2026-10-28. Finding numbers below refer to that report.

| Audit finding | Task |
|---|---|
| 1 Public signing key | Task 1 |
| 2 Leak when leaving the screen during load | Task 2 |
| 3 Worker never frees the model | Task 2 |
| 4 "Try again" grows the review interval | Task 3 |
| 5 Day math on daylight-saving days | Task 4 |
| 6 73 MB model read on each teacher screen | Task 2 |
| 7 Stuck `.part` download, no test | Task 5 |
| 8 Unused dependencies | Task 6 |
| 9 Dead code and files | Task 6 |

## Global Constraints

- Add no new dependency (no `pubspec.yaml` additions).
- Match the existing style: short `///` doc comments in simple English, the same names and patterns as the code around them.
- Do not delete or shorten existing comments that the task does not change.
- After each task, `flutter analyze` reports "No issues found!" and `flutter test` passes.
- The audio never leaves the phone. Do not add network calls other than the existing audio download.
- A shortcut with a known limit gets a comment in this form: `// shortcut: <the limit>, <when to upgrade>`.

## Review Focus

1. Review screen across two surahs: an old speech update from the previous ayah must not be judged as part of the new ayah. Task 2 uses one app-wide attempt counter for this. Check it by hand on the phone (Task 2, Step 6).
2. The speech engine fails to start (for example, a missing model): the screen shows the error, and the next teacher screen tries again. It must not reuse the failed start (Task 2, Step 6).
3. Memorize: a fail, then "Try again" and a pass on the same day. The ayah becomes memorized and is due tomorrow (Task 3 test).
4. Review screen: a pass on a due card still grows the interval (Task 3, updated SM-2 tests).
5. "Download all" meets a surah with a complete `.part` file: that surah fails once, and the next try downloads it (Task 5 test).

---

### Task 1: Private release signing key (finding 1)

**Files:**
- Modify: `android/app/build.gradle.kts:32-48`
- Modify: `.github/workflows/build.yml`
- Modify: `README.md` (section "Install on a phone")
- Delete: `android/app/test-signing.p12`, `tool/make_test_keystore.py`

**Interfaces:**
- Produces: the environment variables `RATTIL_KEYSTORE` (path to the key file), `RATTIL_KEYSTORE_PASSWORD`, `RATTIL_KEY_ALIAS` and `RATTIL_KEY_PASSWORD`, which Gradle reads.

- [ ] **Step 1 (owner, by hand): Make the key and keep a backup**

```sh
keytool -genkeypair -v -keystore rattil-release.jks -alias rattil -keyalg RSA -keysize 4096 -validity 10000
base64 -w0 rattil-release.jks > rattil-release.b64
gh secret set RATTIL_KEYSTORE_B64 < rattil-release.b64
gh secret set RATTIL_KEYSTORE_PASSWORD
gh secret set RATTIL_KEY_ALIAS      # rattil
gh secret set RATTIL_KEY_PASSWORD
```

Keep `rattil-release.jks` and its passwords in two safe places outside the repo. If you lose the key, no later build can update the app. Then delete `rattil-release.b64`.

- [ ] **Step 2: Change the Gradle signing**

Replace the `signingConfigs` and `buildTypes` blocks. When `RATTIL_KEYSTORE` is set, use the private key. When it is not set (local builds and PR builds), use the debug key:

```kotlin
    // Release key from CI secrets (see .github/workflows/build.yml).
    // Without it (local and PR builds), the debug key signs.
    val releaseKey = System.getenv("RATTIL_KEYSTORE")
    signingConfigs {
        if (releaseKey != null) {
            create("release") {
                storeFile = file(releaseKey)
                storePassword = System.getenv("RATTIL_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("RATTIL_KEY_ALIAS")
                keyPassword = System.getenv("RATTIL_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (releaseKey != null) "release" else "debug")
        }
    }
```

- [ ] **Step 3: Give CI the key**

In `build.yml`, add this step before the `flutter build apk` step. Do not run it for pull requests. On `main`, the build must stop when the secret is missing:

```yaml
      - name: Release signing key
        if: github.event_name != 'pull_request'
        env:
          KEYSTORE_B64: ${{ secrets.RATTIL_KEYSTORE_B64 }}
        run: |
          test -n "$KEYSTORE_B64" || { echo "secret RATTIL_KEYSTORE_B64 is missing"; exit 1; }
          echo "$KEYSTORE_B64" | base64 -d > "$RUNNER_TEMP/release.jks"
          echo "RATTIL_KEYSTORE=$RUNNER_TEMP/release.jks" >> "$GITHUB_ENV"
```

Add `env:` to the `flutter build apk` step with `RATTIL_KEYSTORE_PASSWORD`, `RATTIL_KEY_ALIAS` and `RATTIL_KEY_PASSWORD` from `secrets`.

- [ ] **Step 4: Delete the old key and tell the testers**

Delete `android/app/test-signing.p12` and `tool/make_test_keystore.py`. In the README, under "Install on a phone", add: "Builds before 0.2.<first new run number> used a test key. Uninstall that app once before you install the new one. This deletes its progress." Add the same sentence to the release `body:` in `build.yml`. The old key stays in the Git history. Never use it again.

- [ ] **Step 5: Verify**

Run locally: `flutter build apk --release --split-per-abi --target-platform android-arm64`
Expected: the build succeeds (debug key).

After the CI run on `main`, download `Rattil.apk` from the release and run `apksigner verify --print-certs Rattil.apk`.
Expected: the signer is your new certificate, not `CN=Rattil test builds`.

- [ ] **Step 6: Commit**

```bash
git add android/app/build.gradle.kts .github/workflows/build.yml README.md
git rm android/app/test-signing.p12 tool/make_test_keystore.py
git commit -m "Sign releases with a private key from CI secrets"
```

---

### Task 2: One speech engine per app run (findings 2, 3, 6)

**Files:**
- Modify: `lib/app_scope.dart` (class `AppServices`)
- Modify: `lib/features/teacher/teacher_controller.dart:91-131, 197-205, 269-274`
- Modify: `lib/core/asr/asr_engine.dart:93-97` (delete `dispose`)
- Modify: `lib/core/asr/asr_worker.dart` (delete `_Stop`, `dispose`, `_isolate`)
- Modify: `lib/features/teacher/recite_screen.dart:50`, `lib/features/hifz/memorize_screen.dart:57`, `lib/features/hifz/review_screen.dart:52`

**Interfaces:**
- Produces: `Future<AsrEngine> AppServices.asr()` starts the engine on the first call and returns the same engine on later calls. After a failed start, the next call tries again.
- Produces: `Future<void> TeacherController.init(Future<AsrEngine> engine)` replaces `init()`.

- [ ] **Step 1: Add `asr()` to `AppServices`**

Add a `Future<AsrEngine>? _asr` field. `asr()` returns `_asr ??= AsrEngine.start()`. If that future fails, set `_asr = null`, so the next teacher screen tries again, and rethrow with the original stack trace. Doc comment:

```dart
  /// The speech engine, started on first use and kept for the app's life:
  /// the model takes seconds and about 100 MB to load.
  // shortcut: the model stays in memory after the first teacher screen,
  // free it on app pause if Android kills Rattil in the background on 2 GB phones.
```

- [ ] **Step 2: Change `TeacherController`**

- `init(Future<AsrEngine> engine)`: await it. If the controller was disposed during the wait, return without subscribing. Otherwise, set `_engine` and `_sub` as now. Keep the existing `try/catch` that sets `TeacherPhase.error`.
- Add `bool _disposed = false;`. `dispose()` sets it, cancels `_sub`, and calls `unawaited(_engine?.pause())` only when `phase == TeacherPhase.listening`. It never disposes the engine.
- Replace the per-controller attempt numbers with one app-wide counter: `static int _lastAttempt = 0;`, and in `_listen()` use `_attempt = ++_lastAttempt;`. Without this, a second controller would accept the first controller's late updates with the same number.

- [ ] **Step 3: Pass the engine at the three call sites**

`c.init()` becomes `c.init(_services.asr())` in `recite_screen.dart`, `c.init(_s.asr())` in `memorize_screen.dart`, and `next.init(_s.asr())` in `review_screen.dart`.

- [ ] **Step 4: Delete the teardown code that nothing calls now**

Delete `AsrEngine.dispose()`, `AsrWorker.dispose()`, the `_Stop` class and its `case`, and the `_isolate` field and constructor parameter (`AsrWorker._(this._send, this.updates)`). `Isolate.spawn` stays.

- [ ] **Step 5: Run the checks**

Run: `flutter analyze` and then `flutter test`
Expected: "No issues found!" and all tests pass. No unit test covers this task, because the engine needs the native library and a mic.

- [ ] **Step 6: Verify on a phone**

1. Install the debug build. Open Recite, wait for "Tap to start", go back. Do this 10 times.
2. Run `adb shell dumpsys meminfo com.zarsalene.rattil.app | grep TOTAL` after the 1st open and again after the 10th.
   Expected: the total grows once (the first load) and then stays about the same. It does not grow by about 70 MB each time.
3. Open Recite and go back during "Loading…". Do this 5 times, then repeat step 2. Expected: no growth.
4. The second Recite open shows "Tap to start" in under 1 s.
5. Review screen with due ayahs from two surahs: the first word of the second surah is not marked before you speak.
6. Rename `assets/models/asr.int8.onnx`, build, and open Recite. The error text shows. Restore the file. (In the same app run, a second open tries again and does not show the cached error at once.)

- [ ] **Step 7: Commit**

```bash
git add lib/app_scope.dart lib/core/asr lib/features
git commit -m "Keep one speech engine per app run; fixes leaks and slow teacher start"
```

---

### Task 3: An early pass does not grow the interval (finding 4)

**Files:**
- Modify: `lib/core/progress/learning.dart:48-61` (`review`)
- Test: `test/core/progress/learning_test.dart`

**Interfaces:**
- Consumes: `parseDay(String) -> DateTime` (exists in `learning.dart`; the tests now use it, so Task 6 keeps it).

- [ ] **Step 1: Write the failing tests and update the existing tests**

The existing SM-2 tests review three times on the same `day`. After this fix, that does not grow the interval. Change each later review to happen on the due day: `c = review(c, 5, parseDay(c.due));`. Do this in "first success…", "a failed review forgets…", "ease never goes below 1.3" and "intervals stop growing at one year". Keep all the expected values. Add these tests to the group `review (SM-2)`:

```dart
    test('an early pass on a memorized ayah changes nothing', () {
      final c = review(null, 5, day);
      final again = review(c, 5, day);
      expect(again.reps, 1);
      expect(again.interval, 1);
      expect(again.due, '2026-10-28');
    });

    test('a fail, then a pass on the same day: memorized, due tomorrow', () {
      final c = review(review(null, 2, day), 5, day);
      expect(c.reps, 1);
      expect(c.due, '2026-10-28');
    });

    test('an early fail still forgets the ayah', () {
      final c = review(review(null, 5, day), 1, day);
      expect(c.memorized, isFalse);
      expect(c.lapses, 1);
    });
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `flutter test test/core/progress/learning_test.dart`
Expected: FAIL in "an early pass on a memorized ayah changes nothing" (`reps` is 2).

- [ ] **Step 3: Implement**

In `review()`, after `q` is known: `if (q >= 3 && old.memorized && !old.isDue(today)) return old;`. Add one comment line above it: `// A pass before the due day (a retry) is not a review: the interval stays.`

- [ ] **Step 4: Run the tests to see them pass**

Run: `flutter test test/core/progress/`
Expected: PASS, including `progress_store_test.dart`.

- [ ] **Step 5: Commit**

```bash
git add lib/core/progress/learning.dart test/core/progress/learning_test.dart
git commit -m "An early pass does not grow the review interval"
```

---

### Task 4: Calendar day math (finding 5)

**Files:**
- Modify: `lib/core/progress/learning.dart` (add `addDays`; use it in `review` and `streak`)
- Modify: `lib/core/progress/progress_store.dart:88-90` (`recitedLastDays`)
- Modify: `.github/workflows/build.yml` (one test step)
- Test: `test/core/progress/learning_test.dart`

**Interfaces:**
- Produces: `DateTime addDays(DateTime d, int days)` in `learning.dart`. It returns local midnight of the calendar day `days` after `d`, using `DateTime(d.year, d.month, d.day + days)`.

- [ ] **Step 1: Write the failing tests**

Add a group `calendar days`:

```dart
    test('day steps follow the calendar across clock changes', () {
      expect(dayKey(addDays(DateTime(2027, 3, 29), -1)), '2027-03-28'); // spring, Europe
      expect(dayKey(addDays(DateTime(2026, 10, 24), 8)), '2026-11-01'); // autumn, Europe
    });

    test('a streak across the spring clock change counts every day', () {
      expect(streak({'2027-03-27', '2027-03-28', '2027-03-29'}, DateTime(2027, 3, 29)), 3);
    });
```

- [ ] **Step 2: Run the tests to see them fail**

Run (Linux, macOS or CI; Windows ignores `TZ`): `TZ=Europe/Paris flutter test test/core/progress/learning_test.dart`
Expected: FAIL. `addDays` is not defined. When you write `addDays` first, the streak test still fails with 2.

- [ ] **Step 3: Implement**

Add `addDays`. Replace each `Duration(days: …)` step:
- `review`: `_date(today).add(Duration(days: 1))` becomes `addDays(today, 1)`, and `…Duration(days: interval)` becomes `addDays(today, interval)`.
- `streak`: each `d.subtract(const Duration(days: 1))` becomes `addDays(d, -1)`. In `week`, use `addDays(x, 1 - x.weekday)`.
- `recitedLastDays`: `today.subtract(Duration(days: i))` becomes `addDays(today, -i)`.

Delete `_date` if no code uses it after this change.

- [ ] **Step 4: Run the tests in a daylight-saving zone on CI**

In `build.yml`, after `- run: flutter test`, add: `- run: TZ=Europe/Paris flutter test test/core/progress/`
Run locally: `flutter test test/core/progress/`
Expected: PASS. Push the branch and check that the CI step passes.

- [ ] **Step 5: Commit**

```bash
git add lib/core/progress test/core/progress .github/workflows/build.yml
git commit -m "Step days by the calendar, not by 24 hours"
```

---

### Task 5: Download test and the stuck `.part` file (finding 7)

**Files:**
- Modify: `lib/core/audio/audio_catalog.dart:179-183` (`download`)
- Create: `test/core/audio/download_test.dart`

**Interfaces:**
- Consumes: `AudioCatalog(Reciter, {AssetBundle? bundle, Future<Directory> Function()? storageDir})`, `load()`, `download(int)`, `isAvailable(int)`, `downloadErrors`.

- [ ] **Step 1: Write the failing tests**

Test setup in `download_test.dart`:
- Use `test()`, not `testWidgets()`. Do not call `TestWidgetsFlutterBinding.ensureInitialized()`, because that binding replaces `HttpClient` with one that answers 400.
- Start an `HttpServer` on `127.0.0.1:0` that serves a 1000-byte body. With no `Range` header, it answers 200 and the whole body. With `Range: bytes=k-` and `k < 1000`, it answers 206 and the bytes from `k`. With `k >= 1000`, it answers 416. Add a switch so the server can send only 600 bytes.
- Use a fake bundle: a `CachingAssetBundle` subclass whose `load` returns this JSON for `assets/quran/audio_alafasy.json`: `{"surahs":[{"s":1,"url":"http://127.0.0.1:<port>/1.mp3","bytes":1000,"ayahs":[]}]}`.
- Build `AudioCatalog(Reciter.alafasy, bundle: fake, storageDir: () async => tempDir)` and call `await load()`. The `.part` path is `<tempDir>/audio/alafasy/s001.mp3.part`.

Tests:
1. `'a new download saves the whole file'`: `isAvailable(1)` is true, and `s001.mp3` is 1000 bytes, the same as the body.
2. `'a partial download resumes from the .part file'`: write the first 400 bytes to `.part` first. The result is the same 1000 bytes. The server saw `Range: bytes=400-`.
3. `'a short file is an error and leaves nothing behind'`: the server sends 600 bytes. `downloadErrors` has key 1, and neither `s001.mp3` nor `.part` exists.
4. `'a complete .part file does not block the surah forever'`: write all 1000 bytes to `.part`. The first `download(1)` gives an error, and `.part` no longer exists. A second `download(1)` makes `isAvailable(1)` true.

- [ ] **Step 2: Run the tests to see them fail**

Run: `flutter test test/core/audio/download_test.dart`
Expected: tests 1 to 3 PASS. Test 4 FAILS: `.part` still exists after the 416.

- [ ] **Step 3: Implement**

Before the existing status check in `download()`: when `res.statusCode == HttpStatus.requestedRangeNotSatisfiable`, delete `part` and throw `const HttpException('HTTP 416')`. Add one comment: `// The .part file is already whole or wrong: start again next time.`

- [ ] **Step 4: Run the tests to see them pass**

Run: `flutter test test/core/audio/download_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/audio/audio_catalog.dart test/core/audio/download_test.dart
git commit -m "Test audio downloads; a complete .part file no longer blocks a surah"
```

---

### Task 6: Delete unused dependencies, code and files (findings 8, 9)

**Files:**
- Modify: `pubspec.yaml:36-42` (delete `cupertino_icons` with its two comment lines, and `flutter_riverpod`)
- Modify: `lib/core/asr/pcm.dart` (delete `noiseDbfs`, `speechDbfs`, `reset`)
- Modify: `lib/core/asr/asr_worker.dart` (delete `AsrUpdate.decodeMs`, its constructor parameter, doc comment and the `Stopwatch`)
- Modify: `lib/core/align/session.dart` (delete `isFinished`; keep `isPaused`, a test uses it)
- Modify: `README.md` (delete the `prototype-pwa` table row), `PLAN.md:46` (delete `prototype-pwa/ (old web prototype, not shipped)`)
- Delete: `prototype-pwa/`, `Gemini_Generated_Image_8u1b5g8u1b5g8u1b.jpeg`

Keep `parseDay`: Task 3 tests use it now.

- [ ] **Step 1: Check that nothing uses them**

Run: `grep -rn "riverpod\|cupertino\|noiseDbfs\|speechDbfs\|isFinished\|decodeMs\|Gemini_Generated\|prototype-pwa" lib test tool android .github README.md PLAN.md AGENT_PROMPT.md pubspec.yaml`
Expected: matches only in the lines this task deletes. Also run `grep -rn "meter.reset\|\.reset()" lib test`. Expected: only `vad.reset()` in `asr_worker.dart`, which stays.

- [ ] **Step 2: Delete them**

Delete the items listed under **Files**, then run `flutter pub get`. This updates `pubspec.lock`.

- [ ] **Step 3: Run the checks**

Run: `flutter analyze` and then `flutter test`
Expected: "No issues found!" and all tests pass.

- [ ] **Step 4: Commit**

```bash
git add -A pubspec.yaml pubspec.lock lib README.md PLAN.md
git rm -r prototype-pwa Gemini_Generated_Image_8u1b5g8u1b5g8u1b.jpeg
git commit -m "Remove unused dependencies, code and the old web prototype"
```
