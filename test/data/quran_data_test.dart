import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/core/align/units.dart';
import 'package:rattil/core/quran/quran_repo.dart';

/// Integrity gate for assets/quran: the app's text must be the source text.
/// Expected strings are read from the pinned source file, never typed here.
void main() {
  final xml = File('data/raw/tanzil/quran-uthmani.xml').readAsStringSync();
  final meta = File('data/raw/tanzil/quran-data.xml').readAsStringSync();

  String unescape(String s) => s
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');

  // surah -> ayah -> verbatim source text
  final source = <int, Map<int, String>>{};
  final basmala = <int, String?>{};
  final suraRe = RegExp(r'<sura index="(\d+)"[^>]*>([\s\S]*?)</sura>');
  final ayaRe = RegExp(r'<aya index="(\d+)" text="([^"]*)"( bismillah="([^"]*)")?');
  for (final m in suraRe.allMatches(xml)) {
    final s = int.parse(m.group(1)!);
    source[s] = {};
    for (final a in ayaRe.allMatches(m.group(2)!)) {
      final n = int.parse(a.group(1)!);
      source[s]![n] = unescape(a.group(2)!);
      if (n == 1) basmala[s] = a.group(4) == null ? null : unescape(a.group(4)!);
    }
  }
  final metaAyas = {
    for (final m in RegExp(r'<sura index="(\d+)" ayas="(\d+)"').allMatches(meta))
      int.parse(m.group(1)!): int.parse(m.group(2)!),
  };

  QSurah load(int s) => QSurah.fromJson(
      jsonDecode(File('assets/quran/s${s.toString().padLeft(3, '0')}.json').readAsStringSync()) as Map<String, dynamic>);

  test('114 surahs and 6236 ayahs, matching the metadata', () {
    expect(source.length, 114);
    expect(source.values.fold<int>(0, (n, m) => n + m.length), 6236);
    final index = jsonDecode(File('assets/quran/index.json').readAsStringSync()) as List;
    expect(index, hasLength(114));
    for (var s = 1; s <= 114; s++) {
      expect(load(s).ayahs.length, metaAyas[s], reason: 'surah $s');
      expect((index[s - 1] as Map)['ayas'], metaAyas[s], reason: 'index surah $s');
    }
  });

  test('every displayed ayah is exactly the source text', () {
    for (var s = 1; s <= 114; s++) {
      final surah = load(s);
      for (final a in surah.ayahs) {
        final shown = a.words.map((w) => w.mark == null ? w.text : '${w.text} ${w.mark}').join(' ');
        expect(shown, source[s]![a.number], reason: '$s:${a.number}');
      }
    }
  });

  test('basmala: above every surah but 1 and 9, verbatim from the source', () {
    expect(load(1).basmala, isNull, reason: 'in surah 1 the basmala is ayah 1');
    expect(load(9).basmala, isNull);
    for (var s = 2; s <= 114; s++) {
      if (s == 9) continue;
      expect(load(s).basmala, isNotNull, reason: 'surah $s');
      expect(load(s).basmala, basmala[s], reason: 'surah $s');
    }
  });

  test('golden ayahs 1:1-7, 2:255, 114:6 equal the source file', () {
    for (final (s, a) in [for (var i = 1; i <= 7; i++) (1, i), (2, 255), (114, 6)]) {
      final ayah = load(s).ayahs[a - 1];
      final shown = ayah.words.map((w) => w.mark == null ? w.text : '${w.text} ${w.mark}').join(' ');
      expect(shown, source[s]![a]);
    }
  });

  test('every word has phonemes the teacher can read', () {
    for (var s = 1; s <= 114; s++) {
      for (final a in load(s).ayahs) {
        for (final w in a.words) {
          expect(w.phonemes, isNotEmpty, reason: '$s:${a.number} ${w.text}');
          expect(() => toUnits(w.phonemes), returnsNormally, reason: '$s:${a.number}');
          for (final v in w.variants) {
            expect(() => toUnits(v), returnsNormally, reason: '$s:${a.number} variant');
          }
        }
      }
    }
  });
}
