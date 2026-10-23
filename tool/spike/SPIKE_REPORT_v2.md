# ASR spike report

Model: `swaraadam/quran-phoneme-zipformer/model.int8.onnx`
Audio: everyayah `Alafasy_64kbps`

## 1:1 (6.0 s, 4 words)

```
text: بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ
ref : بِسمِللَااهِررَحمَاانِررَحِۦۦۦۦم
hyp : بِسمِللَااهِررَحمَاانِررَحِۦۦم
char edits: 2 / 32 (6.25%), RTF 0.214
```

## 1:7 (13.2 s, 9 words)

```
text: صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ
ref : صِرَااطَللَذِۦۦنَءَنعَمتَعَلَيهِمغَيرِلمَغضُۥۥبِعَلَيهِموَلَضضَااااااللِۦۦۦۦن
hyp : صِرَااطَللَذِۦۦنَءَنعَمتَعَلَيهِمغَيرِلمَغضُۥۥبِعَلَيهِموَلَضضَااااااللِۦۦن
char edits: 2 / 77 (2.60%), RTF 0.229
```

## 2:255 (52.0 s, 46 words)

```
text: ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ لَا تَأْخُذُهُۥ سِنَةٌۭ وَلَا نَوْمٌۭ لَّهُۥ مَا فِى ٱلسَّمَـٰوَٰتِ وَمَا فِى ٱلْأَرْضِ مَن ذَا ٱلَّذِى يَشْفَعُ عِندَهُۥٓ إِلَّا بِإِذْنِهِۦ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلَا يُحِيطُونَ بِشَىْءٍۢ مِّنْ عِلْمِهِۦٓ إِلَّا بِمَا شَآءَ وَسِعَ كُرْسِيُّهُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضَ وَلَا يَـُٔودُهُۥ حِفْظُهُمَا وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ
ref : ءَللَااهُلَااااءِلَااهَءِللَااهُوَلحَييُلقَييُۥۥمُلَااتَءخُذُهُۥۥسِنَتُوووَلَاانَومُللَهُۥۥمَاافِسسَمَااوَااتِوَمَاافِلءَرضِمَںںںذَللَذِۦۦيَشفَعُعِںںںدَهُۥۥۥۥءِللَاابِءِذنِهِۦۦيَعلَمُمَاابَينَءَيدِۦۦهِموَمَااخَلفَهُموَلَاايُحِۦۦطُۥۥنَبِشَيءِممممِنعِلمِهِۦۦۦۦءِللَاابِمَااشَااااءَوَسِعَكُرسِييُهُسسَمَااوَااتِوَلءَرضَوَلَاايَءُۥۥدُهُۥۥحِفظُهُمَااوَهُوَلعَلِييُلعَظِۦۦۦۦم
hyp : ءَللَااهُلَااااءِلَااهَءِللَااهُوَلحَييُلقَييُۥۥملَااتَءخُذُهُۥۥسِنَتُوووَلَاانَۥۥملَهُۥۥمَاافِسسَمَااوَااتِوَمَاافِلءَرضِمَںںںذَللَذِۦۦيَشفَعُعِںںںدَهُۥۥۥۥءِللَاابِءِذنِهِۦۦيَعلَمُمَاابَينَءَيدِۦۦهِموَمَااخَلفَهُموَلَاايُحِۦۦطُۥۥنَبِشَيءِممممِنعِلمِهِۦۦۦۦءِللَاابِمَااشَااااءَوَسِعَكُرسِييُهُسسَمَااوَااتِوَلءَرضِوَلَاايَءُۥۥدُهُۥۥحِفبُهُمَااوَهُوَلعَلِييُلعَظِۦۦم
char edits: 9 / 369 (2.44%), RTF 0.181
```

## 112:1 (3.0 s, 4 words)

```
text: قُلْ هُوَ ٱللَّهُ أَحَدٌ
ref : قُلهُوَللَااهُءَحَدڇ
hyp : قُلهُوَللَااهُءَحَدڇ
char edits: 0 / 20 (0.00%), RTF 0.324
```

## 114:6 (8.3 s, 3 words)

```
text: مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ
ref : مِنَلجِننننَتِوَننننَااااس
hyp : مِنَلجِننننَتِوَننننَااس
char edits: 2 / 26 (7.69%), RTF 0.172
```

## Alphabet check

- Overall character error rate vs reference: 2.86%
- quran-transcript phonetic alphabet: 42 characters
- Model tokens.txt characters not in that alphabet: none
- Alphabet characters missing from tokens.txt: none
- Characters in model output not in that alphabet: none

## Teacher verdict on these outputs (lib/core/align, default thresholds)

66 words, all recited correctly by a professional reciter.

| Result | Words | Cause |
|---|---|---|
| correct, no marks | 57 | |
| low hint: madd length | 4 | Ayah-end madd aarid recited at 2 counts (a valid choice); reference fixes it at 4 |
| medium: harakat | 3 | ASR errors |
| high: false "wrong" | 2 | 2:255 `حِفظُ` heard with ب for ظ; 2:255 `نَومُ للَهُ` heard as a madd waw |

False stops: 2 / 66 words (3.0%). Target is < 2%. v3 (PER 1.43% vs 5.19% for v2) is expected to do better.

## Conclusion

- The spike passes: the model runs in sherpa-onnx (streaming CTC), and its alphabet is the quran-transcript alphabet. No mapping is needed.
- v2 is usable for development now. v3 has the same interface and tokens, so switching is a file swap.
- To fix before release: ayah-end madd aarid hints (free choice), and the false-stop rate (measure in tool/eval, then tune or require v3).
