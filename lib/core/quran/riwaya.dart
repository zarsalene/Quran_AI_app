import 'dart:convert';

import 'package:flutter/services.dart';

import 'quran_repo.dart';

/// A riwaya (transmission) of a qira'a. Hafs uses the Tanzil text and has the
/// teacher; the others use the King Fahd Complex text (tool/data/build_qiraat.py).
enum Riwaya {
  hafs(asset: null, font: 'AmiriQuran', mp3quranId: 1, teacher: true),
  qalun(asset: 'qalun', font: 'QPCQalun', mp3quranId: 5),
  warsh(asset: 'warsh', font: 'QPCWarsh', mp3quranId: 2),
  shuba(asset: 'shuba', font: 'QPCShuba', mp3quranId: 15),
  bazzi(asset: 'bazzi', font: 'QPCBazzi', mp3quranId: 4),
  qunbul(asset: 'qunbul', font: 'QPCQunbul', mp3quranId: 6);

  const Riwaya({required this.asset, required this.font, required this.mp3quranId, this.teacher = false});

  /// assets/qiraat/<asset>.json, or null for Hafs (assets/quran).
  final String? asset;

  /// Font family that renders this text correctly.
  final String font;

  /// Riwaya id in the mp3quran.net API, for reciters.
  final int mp3quranId;

  /// The speech model knows this riwaya (only Hafs for now).
  final bool teacher;

  /// The basmala is ayah 1 of Al-Fatiha in the Kufi count (Hafs, Shu'ba).
  bool get fatihaBasmalaIsAyah => this == hafs || this == shuba;
}

/// The text of one riwaya other than Hafs, with its own ayah count, pages,
/// and juz. Words are split on spaces only; the text is verbatim.
class RiwayaText {
  RiwayaText._(this.riwaya, this._ayahs, this.meta);

  final Riwaya riwaya;
  final List<List<String>> _ayahs; // [surah - 1][ayah - 1]
  final QuranMeta meta;

  static Future<RiwayaText> load(Riwaya r, AssetBundle bundle) async {
    final j = jsonDecode(await bundle.loadString('assets/qiraat/${r.asset}.json')) as Map<String, dynamic>;
    final ayahs = <List<String>>[];
    final pages = <AyahRef>[];
    final juz = <AyahRef>[];
    var lastPage = 0, lastJuz = 0;
    for (final s in j['surahs'] as List) {
      final n = (s as Map<String, dynamic>)['s'] as int;
      final texts = <String>[];
      var a = 0;
      for (final row in s['a'] as List) {
        a++;
        final list = row as List;
        texts.add(list[0] as String);
        final page = list[1] as int, jz = list[2] as int;
        if (page > lastPage) {
          pages.add((surah: n, ayah: a));
          lastPage = page;
        }
        if (jz > lastJuz) {
          juz.add((surah: n, ayah: a));
          lastJuz = jz;
        }
      }
      ayahs.add(texts);
    }
    return RiwayaText._(r, ayahs, QuranMeta.of(pages: pages, juz: juz));
  }

  int ayahCount(int surah) => _ayahs[surah - 1].length;

  QSurah surah(int n) => QSurah(
        number: n,
        basmala: null, // shown as the U+FDFD ligature, never typed
        ayahs: [
          for (var i = 0; i < _ayahs[n - 1].length; i++)
            QAyah(i + 1, [
              for (final w in _ayahs[n - 1][i].split(' '))
                if (w.isNotEmpty) QWord(text: w, phonemes: ''),
            ]),
        ],
      );
}
