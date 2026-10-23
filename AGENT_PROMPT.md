# Build "Rattil" (رتّل): an offline Quran learning app with a live recitation teacher

## Role
You are a senior Flutter engineer with Quran-tech experience. Build a free Android app (APK) that teaches people to read, memorize, and recite the Quran correctly. Work on your own. Ask me only for things you cannot get yourself (Hugging Face token, GitHub repo access, final app name).

## Rules that cannot change (in priority order)
1. **Quran text is 100% correct.** Never type, generate, translate, or "fix" Quran text. Load it only from the verified source files below. A text error blocks release.
2. **The teacher is honest.** It flags real mistakes and never praises a wrong recitation. When it is not sure, it says "Not sure. Listen to the reciter" and does not say "correct".
3. **Offline.** Text, the teacher, and bundled audio work in airplane mode. Other audio downloads once, then works offline.
4. **Simple.** A 7-year-old and a 70-year-old can use it with no help.
5. **Free.** No ads, no account, no analytics. Network is used only for audio and model downloads.

## Stack
- Flutter stable, Dart, Android only, minSdk 24, ABIs arm64-v8a and armeabi-v7a.
- Packages: riverpod (state), drift or sqflite (`quran.db`), just_audio (audio), record (mic at 16 kHz mono PCM16), sherpa_onnx (ASR and VAD), flutter_local_notifications (reminders).
- **No Android Studio.** Build in GitHub Actions: `ubuntu-latest`, `subosito/flutter-action`, `flutter build apk --release --split-per-abi`, then upload the APKs as artifacts. In the README, also document a local CLI build (Flutter SDK, Android cmdline-tools, JDK 17).

## Data (a build script downloads it, verifies it, and writes `assets/quran.db`)
| Item | Source | Notes |
|---|---|---|
| Uthmani Hafs text and matching font | QUL: qul.tarteel.ai/resources (KFGQPC Uthmanic Hafs script and font) | Use text and font as a **matched pair**, so small marks render correctly |
| Cross-check text | Tanzil Uthmani: tanzil.net/download | CC-BY 3.0, verbatim only. Credit Tanzil and link tanzil.net |
| Mushaf layout (604 pages) | QUL "Mushaf layouts" | page, line, word mapping |
| Metadata | QUL or Tanzil | surahs, ayah counts, juz, hizb, sajdah |
| Audio (per ayah) | everyayah.com, e.g. `everyayah.com/data/Alafasy_64kbps/001001.mp3` | Reciters: Alafasy, and Husary Muallim (teaching pace) |
| Word timings | QUL "Recitations and segments" | Must match the reciter |
| Phonetic reference | `quran-transcript` (pip, from github obadx/quran-muaalem) | Generate per-word phonemes at build time. Store them in `quran.db` |
| Translations (optional) | Tanzil: Sahih International (en), Hamidullah (fr) | Check the license first |

Bundle in the APK: the full text, the ASR model, and audio for Al-Fatiha and Juz 30 (one reciter). Everything else downloads per surah: resumable, cached, size shown before download, plus a "Download all" option.

### Data integrity gate (CI fails if a check fails)
- 114 surahs and 6236 ayahs. The ayah count of each surah matches the metadata.
- Word-level diff of QUL text against Tanzil text, after normalization (strip diacritics, tatweel, alif forms): **0 differences**.
- SHA-256 of each source file is pinned in `data/CHECKSUMS`.
- Golden tests for 1:1-7, 2:255, and 114:6. Copy the expected strings from the source file. Do not type them.
- Golden screenshot tests for 3 Mushaf pages, to catch font problems.
- Displayed text gets no string transforms. Normalization is for search and matching only.

## The Teacher (core feature): real-time recitation correction
**Engine:** on-device streaming ASR through sherpa_onnx, running in an isolate.
- Primary model: `Quran-Lab/zipformer_p-arabic-v3` on Hugging Face (gated). Streaming CTC ONNX int8, 251-symbol Quran phonetic alphabet, blank id 250, **no language model** (so it does not auto-correct mistakes). License NPL-1.2: the app must be free and must show this text: "Automatic feedback can be wrong. It does not replace a qualified teacher." Ask me for an HF token.
- Fallbacks, if the primary model is blocked: `obadx/muaalem-model-v3_2` exported to ONNX (check its license), or `tarteel-ai/whisper-base-ar-quran` through whisper.cpp (word-level checks only).

**Pipeline**
1. The user picks an ayah range. Load the expected phonemes for each word.
2. Mic stream → VAD → streaming ASR → phoneme tokens.
3. Do an incremental alignment (edit distance that respects word boundaries) inside a window around the current word. If the alignment fails, search ±3 ayahs, then the whole surah, to detect a jump.
4. Classify each word as: correct / wrong / skipped / extra / jumped. A repeat is allowed and gets no penalty.
5. **Confidence levels:**
   - High (word missing, extra, or wrong letter) → **stop**.
   - Medium (harakat, long vowel) → orange mark. No stop by default.
   - Low (tajweed: ghunna, ikhfa, madd length, qalqala) → hint only, labeled "beta". The model card says ikhfa and madd length are unreliable. Never stop for these.
6. **Stop behavior (Strict mode):** confirm the mistake (2 consistent chunks, or the reader is past the word), then pause the mic, vibrate lightly, mark the word red, play the correct word (audio clip cut with the word timings), and ask the user to repeat from that word. Continue only when the word is correct. "Gentle" mode marks the mistake and does not stop.
7. Show "Perfect" only when every word matched with high confidence.
8. If the noise level is too high, say so. Do not judge the recitation.
9. Memorization mode: words stay hidden and show as the user recites each one correctly.

**Prove accuracy (`tool/eval`, results in `EVAL.md`)**
- Clean recitations from 3 everyayah reciters (not used for tuning): target false-stop rate **< 2%**.
- Synthetic mistakes (skip, swap, or insert words by joining word clips): target recall **> 95%** for each error type.
- Tajweed: report results on obadx `qdat_bench`.
- Tune thresholds with this eval. Do not guess them.
- Low-end phone (2–3 GB RAM): **< 500 ms** latency per word, no ANR.

## Features (build in this order)
1. **Read:** Mushaf page view and ayah list, Arabic search (normalized), bookmarks, resume at last position. Correct basmala: on every surah except 9; in surah 1 it is ayah 1.
2. **Listen:** play an ayah, repeat it N times, loop a range, speed 0.75–1.25×, word highlight.
3. **Recite (Teacher):** as specified above.
4. **Memorize:** for each ayah: listen 3× → read along → recite with hidden words → test. Reviews use SM-2 spaced repetition.
5. **Progress:** streak, daily goal, surah mastery map, weekly chart.

## Engagement (respectful, no gambling mechanics, no shaming)
- The first suggestion is short Juz 30 surahs, so new users get quick wins.
- Daily goal (minutes or ayahs). Streak with 1 free "freeze" per week. Local reminder at a time the user picks.
- Mastery map: each surah is colored by level. Small celebration when a surah is memorized. Badges: first surah, Juz Amma, 7-day streak.
- No leaderboards.

## UX
- Home: one big "Continue" button and 3 tiles (Read · Listen · Recite & Memorize). Reciting starts within 2 taps.
- UI languages: Arabic (RTL), English, French (ARB l10n). Onboarding is 3 screens or fewer. Explain the mic before the permission prompt.
- Touch targets ≥ 48 dp, font-size slider, dark mode, TalkBack labels.
- No music, no images near Quran text.
- Attribution screen: Tanzil, QUL/KFGQPC, everyayah, the ASR model and its license.

## Architecture
`lib/core/{db,audio,asr,align}`, `lib/features/{reader,listen,teacher,hifz,progress,settings}`, `lib/l10n`. Alignment and scoring are pure Dart with full unit tests.

## How to work
1. **Spike first (before you build the app):** run the ASR model in a CLI on 5 clips. Print its phonemes next to the `quran-transcript` reference and confirm the 2 alphabets match (if not, write a mapping and test it). If the spike fails, report it and propose the fallback. Do not fake results.
2. Write `PLAN.md` (1 page maximum), then build in vertical slices. After each slice, `flutter analyze`, `flutter test`, and the CI APK build must pass.
3. **Done means:** the APK installs on a real phone. In airplane mode, text, bundled audio, and the Teacher work. The integrity gate passes. `EVAL.md` meets the targets. The README has install steps.

**Never:** invent Quran text, translate the Quran with AI, give religious rulings, add analytics, or make network calls other than audio and model downloads.
