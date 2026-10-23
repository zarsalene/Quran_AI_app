# Rattil (رتّل): build plan

Full spec: [AGENT_PROMPT.md](AGENT_PROMPT.md). Each slice ends with `flutter analyze`, `flutter test`, and a green CI APK build.

## 0. Spike: done with v2 (see tool/spike/SPIKE_REPORT_v2.md)
- [x] Reference phonemes from `quran-transcript` for 5 clips. Text comes from the package data, not typed.
- [x] `zipformer_p-arabic-v2` int8 (public mirror, NPL-1.1) runs in sherpa-onnx: 2.86% character error, 4-6x faster than real time on a PC.
- [x] Alphabet: tokens.txt and quran-transcript have the same 42 characters. No mapping needed.
- [ ] v3 (gated, waiting for approval): same interface, swap when approved. Expected fewer false stops (v2: 2 of 66 words).

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
