import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/core/align/models.dart';
import 'package:rattil/core/align/session.dart';
import 'package:rattil/core/align/units.dart';

/// Real ASR output of zipformer_p-arabic-v2 on 5 clean Alafasy clips
/// (tool/spike/SPIKE_REPORT_v2.md), checked against quran-transcript phonemes.
void main() {
  final ref = jsonDecode(File('test/fixtures/reference_words.json').readAsStringSync()) as Map;
  final hyp = jsonDecode(File('test/fixtures/asr_v2_alafasy.json').readAsStringSync()) as Map;

  Map<int, WordResult> judge(String key) {
    final words = List<String>.from(ref[key] as List);
    final s = TeacherSession(
      stream: ExpectedStream(words),
      rangeStart: 0,
      rangeEnd: words.length,
      wordAyah: List.filled(words.length, 1),
      mode: TeacherMode.gentle,
    );
    s.update(hyp[key] as String, atPause: true);
    s.update(hyp[key] as String, atPause: true);
    return s.results;
  }

  test('no madd-length hint at an ayah end (the reader chooses 2, 4 or 6)', () {
    for (final key in ref.keys) {
      final results = judge(key as String);
      final last = results[results.keys.reduce((a, b) => a > b ? a : b)]!;
      expect(last.issues.where((i) => i.type == IssueType.maddLength), isEmpty, reason: key);
    }
  });

  test('baseline with v2: 2 false "wrong" words in 66 correct ones', () {
    // Known model errors, see SPIKE_REPORT_v2.md. If this count changes,
    // update the report and EVAL.md: it is the false-stop rate.
    var wrong = 0, total = 0;
    for (final key in ref.keys) {
      final results = judge(key as String);
      total += results.length;
      wrong += results.values.where((r) => r.status == WordStatus.wrong).length;
    }
    expect(total, 66);
    expect(wrong, 2);
  });
}
