import 'dart:convert';

import 'package:flutter/services.dart';

/// One word as shown, with its expected phonemes.
class QWord {
  const QWord({required this.text, this.mark, required this.phonemes, this.variants = const []});

  /// Display text, verbatim from the source file.
  final String text;

  /// Pause mark(s) after the word, verbatim, or null.
  final String? mark;

  /// Expected phonemes (quran-transcript), as recited in the default way.
  final String phonemes;

  /// Other correct forms: waqf at a pause mark, a fresh start after one, or
  /// wasl into the next ayah.
  final List<String> variants;

  factory QWord.fromJson(Map<String, dynamic> j) => QWord(
        text: j['t'] as String,
        mark: j['m'] as String?,
        phonemes: j['p'] as String,
        variants: List<String>.from((j['v'] as List?) ?? const []),
      );
}

class QAyah {
  const QAyah(this.number, this.words);
  final int number;
  final List<QWord> words;
}

class QSurah {
  const QSurah({required this.number, required this.basmala, required this.ayahs});
  final int number;

  /// The basmala shown above the surah, verbatim from the source. Null for
  /// surah 9, and for surah 1 where the basmala is ayah 1.
  final String? basmala;
  final List<QAyah> ayahs;

  factory QSurah.fromJson(Map<String, dynamic> j) => QSurah(
        number: j['s'] as int,
        basmala: j['basmala'] as String?,
        ayahs: [
          for (final a in j['ayahs'] as List)
            QAyah(a['a'] as int, [for (final w in a['w'] as List) QWord.fromJson(w as Map<String, dynamic>)]),
        ],
      );
}

class SurahInfo {
  const SurahInfo({required this.number, required this.name, required this.tname, required this.ename, required this.ayahs});
  final int number;
  final String name;
  final String tname;
  final String ename;
  final int ayahs;

  factory SurahInfo.fromJson(Map<String, dynamic> j) => SurahInfo(
        number: j['s'] as int,
        name: j['name'] as String,
        tname: j['tname'] as String,
        ename: j['ename'] as String,
        ayahs: j['ayas'] as int,
      );
}

/// Reads the bundled Quran data built by tool/data/build_quran.py.
class QuranRepo {
  QuranRepo([AssetBundle? bundle]) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  List<SurahInfo>? _index;
  final Map<int, QSurah> _cache = {};

  Future<List<SurahInfo>> surahs() async {
    return _index ??= [
      for (final j in jsonDecode(await _bundle.loadString('assets/quran/index.json')) as List)
        SurahInfo.fromJson(j as Map<String, dynamic>),
    ];
  }

  Future<QSurah> surah(int number) async {
    final cached = _cache[number];
    if (cached != null) return cached;
    final name = 'assets/quran/s${number.toString().padLeft(3, '0')}.json';
    final s = QSurah.fromJson(jsonDecode(await _bundle.loadString(name)) as Map<String, dynamic>);
    return _cache[number] = s;
  }
}
