# Rattil (رتّل): build plan

Full spec: [AGENT_PROMPT.md](AGENT_PROMPT.md). Each slice ends with `flutter analyze`, `flutter test`, and a green CI APK build.

## 0. Spike (now)
- [x] Reference phonemes from `quran-transcript` for 5 clips (1:1, 1:7, 2:255, 112:1, 114:6). Text comes from the package data, not typed.
- [ ] Run `Quran-Lab/zipformer_p-arabic-v3` int8 ONNX (sherpa-onnx, streaming CTC) on the 5 clips. **Blocked: HF access waits for manual approval.**
- [ ] Confirm the model's `tokens.txt` alphabet matches `quran-transcript`. If not, write and test a mapping.
- Fallback if refused: `muaalem-model-v3_2` (MIT, 2.4 GB fp32, too big for 2–3 GB phones) or `whisper-base-ar-quran` (word-level only).

## 1. Data pipeline + integrity gate (`tool/data`, Python)
- Download QUL Hafs text + KFGQPC font, QUL Mushaf layout, QUL word segments, Tanzil Uthmani, metadata.
- Pin SHA-256 in `data/CHECKSUMS`. Write `assets/quran.db` (surahs, ayahs, words, pages, phonemes per word).
- Gate in CI: 114 / 6236 counts, QUL vs Tanzil normalized word diff = 0, golden strings copied from source files.

## 2. App skeleton + Read
- Flutter project, riverpod, drift, l10n (ar/en/fr), theme, CI workflow (`--split-per-abi`).
- Mushaf page view (604 pages), ayah list, normalized search, bookmarks, resume, basmala rules.
- Golden screenshot tests for 3 pages.

## 3. Listen
- just_audio, bundled Al-Fatiha + Juz 30 (Alafasy), per-surah download (resumable, size shown, "Download all").
- Repeat N, loop range, speed 0.75–1.25×, word highlight from QUL segments.

## 4. Teacher
- `lib/core/align`: pure Dart, word-boundary edit distance, windowed search, jump detection, confidence levels. Full unit tests first.
- `lib/core/asr`: sherpa_onnx in an isolate, VAD, mic at 16 kHz PCM16. Noise check.
- Strict and Gentle modes, word clip playback, "Perfect" only on full high-confidence match. Disclaimer text from the model license.
- `tool/eval` + `EVAL.md`: false stops < 2% on 3 held-out reciters, recall > 95% per synthetic error type, qdat_bench tajweed, latency < 500 ms per word.

## 5. Memorize
- Listen 3× → read along → recite hidden → test. SM-2 reviews.

## 6. Progress + engagement
- Streak (1 freeze/week), daily goal, reminders, mastery map, 3 badges, Juz 30 first suggestion.

## 7. Polish + release
- Onboarding (≤ 3 screens, mic explained first), font slider, dark mode, TalkBack labels, attribution screen.
- README install steps. Airplane-mode test on a real phone.

## Repo layout
`lib/core/{db,audio,asr,align}`, `lib/features/{reader,listen,teacher,hifz,progress,settings}`, `lib/l10n`, `tool/{spike,data,eval}`, `data/`, `prototype-pwa/` (old web prototype, not shipped).
