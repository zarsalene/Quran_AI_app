import 'dart:convert';

import 'package:flutter/services.dart';

import 'riwaya.dart';

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
  const SurahInfo({
    required this.number,
    required this.name,
    required this.tname,
    required this.ename,
    required this.ayahs,
    this.meccan = true,
  });
  final int number;
  final String name;
  final String tname;
  final String ename;
  final int ayahs;
  final bool meccan;

  factory SurahInfo.fromJson(Map<String, dynamic> j) => SurahInfo(
        number: j['s'] as int,
        name: j['name'] as String,
        tname: j['tname'] as String,
        ename: j['ename'] as String,
        ayahs: j['ayas'] as int,
        meccan: j['type'] != 'Medinan',
      );
}

/// A place in the Quran.
typedef AyahRef = ({int surah, int ayah});

int compareRef(AyahRef a, AyahRef b) => a.surah != b.surah ? a.surah - b.surah : a.ayah - b.ayah;

/// Madani page, juz, hizb quarter and sajdah starts (Tanzil metadata).
class QuranMeta {
  QuranMeta._(this.pages, this.juz, this.quarters, this.sajdas);

  factory QuranMeta.fromJson(Map<String, dynamic> j) {
    List<AyahRef> refs(String key) => [
          for (final e in j[key] as List) (surah: (e as List)[0] as int, ayah: e[1] as int),
        ];
    return QuranMeta._(refs('pages'), refs('juz'), refs('quarters'), refs('sajdas').toSet());
  }

  /// Pages and juz of another riwaya's mushaf (no quarters or sajdahs).
  factory QuranMeta.of({required List<AyahRef> pages, required List<AyahRef> juz}) =>
      QuranMeta._(pages, juz, const [], const {});

  /// Start of each page (604), juz (30) and hizb quarter (240), in order.
  final List<AyahRef> pages;
  final List<AyahRef> juz;
  final List<AyahRef> quarters;
  final Set<AyahRef> sajdas;

  /// 1-based number of the division of [starts] that holds [ref].
  static int _find(List<AyahRef> starts, AyahRef ref) {
    var lo = 0, hi = starts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (compareRef(starts[mid], ref) <= 0) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + 1;
  }

  int get pageCount => pages.length;

  int pageOf(AyahRef ref) => _find(pages, ref);
  int juzOf(AyahRef ref) => _find(juz, ref);
  int quarterOf(AyahRef ref) => _find(quarters, ref);
}

/// Reads the bundled Quran data built by tool/data/build_quran.py.
class QuranRepo {
  QuranRepo([AssetBundle? bundle]) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  List<SurahInfo>? _index;
  QuranMeta? _meta;
  final Map<Riwaya, RiwayaText> _riwayat = {};
  final Map<Riwaya, List<SurahInfo>> _infos = {};

  /// Loads the text of [r] once (Hafs is always loaded).
  Future<void> loadRiwaya(Riwaya r) async {
    if (r.asset == null || _riwayat.containsKey(r)) return;
    _riwayat[r] = await RiwayaText.load(r, _bundle);
  }

  bool isLoaded(Riwaya r) => r.asset == null || _riwayat.containsKey(r);

  /// Surahs with the ayah count of [r], after [loadRiwaya].
  List<SurahInfo> infosFor(Riwaya r) {
    final text = _riwayat[r];
    if (text == null) return surahsLoaded;
    return _infos[r] ??= [
      for (final i in surahsLoaded)
        SurahInfo(number: i.number, name: i.name, tname: i.tname, ename: i.ename, ayahs: text.ayahCount(i.number), meccan: i.meccan),
    ];
  }

  QuranMeta metaFor(Riwaya r) => _riwayat[r]?.meta ?? metaLoaded;

  /// Surah [n] in riwaya [r]. Hafs words carry the teacher's phonemes.
  Future<QSurah> surahFor(Riwaya r, int n) async {
    final text = _riwayat[r];
    return text == null ? surah(n) : text.surah(n);
  }
  final Map<int, QSurah> _cache = {};

  Future<List<SurahInfo>> surahs() async {
    return _index ??= [
      for (final j in jsonDecode(await _bundle.loadString('assets/quran/index.json')) as List)
        SurahInfo.fromJson(j as Map<String, dynamic>),
    ];
  }

  Future<QuranMeta> meta() async {
    return _meta ??= QuranMeta.fromJson(jsonDecode(await _bundle.loadString('assets/quran/meta.json')) as Map<String, dynamic>);
  }

  /// All surahs, after [surahs] has loaded once (the app loads it at start).
  List<SurahInfo> get surahsLoaded => _index!;

  /// Pages, juz and quarters, after [meta] has loaded once.
  QuranMeta get metaLoaded => _meta!;

  Future<QSurah> surah(int number) async {
    final cached = _cache[number];
    if (cached != null) return cached;
    final name = 'assets/quran/s${number.toString().padLeft(3, '0')}.json';
    final s = QSurah.fromJson(jsonDecode(await _bundle.loadString(name)) as Map<String, dynamic>);
    return _cache[number] = s;
  }
}
