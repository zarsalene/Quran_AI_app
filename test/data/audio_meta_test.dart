import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/core/audio/audio_catalog.dart';
import 'package:rattil/core/quran/arabic.dart';
import 'package:rattil/core/quran/quran_repo.dart';

/// Integrity of the page metadata and the audio timings against the app's text.
void main() {
  final xml = File('data/raw/tanzil/quran-data.xml').readAsStringSync();
  final meta = QuranMeta.fromJson(jsonDecode(File('assets/quran/meta.json').readAsStringSync()) as Map<String, dynamic>);
  QSurah load(int s) => QSurah.fromJson(
      jsonDecode(File('assets/quran/s${s.toString().padLeft(3, '0')}.json').readAsStringSync()) as Map<String, dynamic>);

  test('meta.json equals the pinned Tanzil metadata', () {
    List<AyahRef> fromXml(String tag) => [
          for (final m in RegExp('<$tag index="\\d+" sura="(\\d+)" aya="(\\d+)"').allMatches(xml))
            (surah: int.parse(m.group(1)!), ayah: int.parse(m.group(2)!)),
        ];
    expect(meta.pages, fromXml('page'));
    expect(meta.juz, fromXml('juz'));
    expect(meta.quarters, fromXml('quarter'));
    expect(meta.pages, hasLength(604));
    expect(meta.juz, hasLength(30));
  });

  test('page and juz lookup', () {
    expect(meta.pageOf((surah: 1, ayah: 1)), 1);
    expect(meta.pageOf((surah: 2, ayah: 1)), 2);
    expect(meta.pageOf((surah: 2, ayah: 5)), 2);
    expect(meta.pageOf((surah: 114, ayah: 6)), 604);
    expect(meta.juzOf((surah: 2, ayah: 141)), 1);
    expect(meta.juzOf((surah: 2, ayah: 142)), 2);
    expect(meta.juzOf((surah: 78, ayah: 1)), 30);
  });

  group('audio timings', () {
    final j = jsonDecode(File('assets/quran/audio_alafasy.json').readAsStringSync()) as Map<String, dynamic>;
    final surahs = j['surahs'] as List;

    test('every surah and ayah has timings; word indexes fit the text', () {
      expect(surahs, hasLength(114));
      var words = 0, missing = 0;
      for (final s in surahs) {
        final n = (s as Map)['s'] as int;
        final text = load(n);
        final ayahs = s['ayahs'] as List;
        expect(ayahs, hasLength(text.ayahs.length), reason: 'surah $n');
        for (var a = 0; a < ayahs.length; a++) {
          final count = text.ayahs[a].words.length;
          final segs = (ayahs[a] as List)[2] as List;
          final seen = <int>{};
          for (final seg in segs) {
            final w = (seg as List)[0] as int;
            expect(w, inInclusiveRange(0, count - 1), reason: '$n:${a + 1}');
            expect(seg[2] as int, greaterThan(seg[1] as int), reason: '$n:${a + 1} segment');
            seen.add(w);
          }
          words += count;
          missing += count - seen.length;
        }
      }
      // A few words of long ayahs have no segment (tool/data/fetch_timings.py).
      expect(missing / words, lessThan(0.01));
    });

    test('a missing word plays from the word before to the word after', () {
      const t = AyahTiming(1000, 5000, [(word: 0, from: 1000, to: 2000), (word: 2, from: 3000, to: 4000)]);
      expect(t.wordSpan(0), (1000, 2000));
      expect(t.wordSpan(1), (1000, 4000));
      expect(t.wordAt(1500), 0);
      expect(t.wordAt(2500), isNull);
    });

    test('a repeated word plays its last reading', () {
      const t = AyahTiming(0, 9000, [
        (word: 0, from: 0, to: 1000),
        (word: 1, from: 1000, to: 2000),
        (word: 1, from: 2000, to: 3000),
      ]);
      expect(t.wordSpan(1), (2000, 3000));
    });

    test('bundled surahs are on disk', () {
      for (final s in AudioCatalog.bundled) {
        expect(File('assets/audio/s${s.toString().padLeft(3, '0')}.mp3').existsSync(), isTrue, reason: 'surah $s');
      }
    });
  });

  group('search normalization', () {
    test('folds alif forms, ta marbuta, alif maqsura, and drops harakat', () {
      expect(normalizeArabic('ٱلرَّحْمَـٰنِ'), 'الرحمن');
      expect(normalizeArabic('ٱلرَّحْمَـٰنِ', daggerAsAlif: true), 'الرحمان');
      expect(normalizeArabic('إِيَّاكَ'), 'اياك');
      expect(normalizeArabic('رَحْمَةً'), 'رحمه');
      expect(normalizeArabic('عَلَىٰ', daggerAsAlif: true), 'عليا');
    });

    test('Arabic digits', () {
      expect(arabicNumber(255), '٢٥٥');
    });
  });
}
