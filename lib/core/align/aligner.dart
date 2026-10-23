import 'dart:typed_data';

import 'compare.dart';
import 'config.dart';
import 'models.dart';
import 'phonetics.dart';
import 'units.dart';

const int _opFree = 0, _opSub = 1, _opIns = 2, _opDel = 3, _opRep = 4;

/// Extra sounds between two words, long enough to be an extra word.
class ExtraSpan {
  const ExtraSpan(this.beforeWord, this.hypStart, this.hypEnd);

  /// The extra sounds come just before this word (wordCount = after the last).
  final int beforeWord;
  final int hypStart;
  final int hypEnd;

  @override
  String toString() => 'Extra(before W$beforeWord, hyp $hypStart..$hypEnd)';
}

class AlignmentResult {
  const AlignmentResult({
    required this.words,
    required this.extras,
    required this.endUnit,
    required this.tailCostPerUnit,
  });

  /// One result per word of the aligned window, in order.
  final List<WordResult> words;
  final List<ExtraSpan> extras;

  /// Expected unit (global index) the reader has reached.
  final int endUnit;

  /// Average alignment cost of the last [TeacherConfig.jumpTailUnits] ASR
  /// units. A high value means the reader is not where we think.
  final double tailCostPerUnit;
}

class _Step {
  const _Step(this.op, this.hyp, this.unit);
  final int op;

  /// ASR unit index consumed, or -1.
  final int hyp;

  /// Local expected unit consumed (sub/del) or gap position (ins).
  final int unit;
}

/// Aligns ASR phoneme units to a window of expected words.
///
/// The alignment is a Viterbi pass over (ASR unit, expected unit) with
/// substitutions, insertions, deletions, and a "repeat" move back to the start
/// of a recent word. When a word is said more than once, its last attempt
/// decides its result, so a reader who repeats to fix a mistake is not
/// penalized.
class Aligner {
  Aligner(this.stream, {this.config = const TeacherConfig(), Map<int, List<String>>? variants})
      : scorer = UnitScorer(config),
        _variants = {
          for (final e in (variants ?? const <int, List<String>>{}).entries)
            e.key: [for (final v in e.value) toUnits(v)],
        };

  final ExpectedStream stream;
  final TeacherConfig config;
  final UnitScorer scorer;

  /// Alternative pronunciations per word (wasl forms at ayah boundaries).
  final Map<int, List<List<PUnit>>> _variants;

  /// [atPause] is true when the reader has stopped speaking (VAD silence).
  /// A word that is only partly matched is then judged as finished, so a
  /// wrong last letter is reported instead of waiting forever.
  AlignmentResult align(List<PUnit> hyp, {int fromWord = 0, int? toWord, bool atPause = false}) {
    final w0 = fromWord, w1 = toWord ?? stream.wordCount;
    final u0 = stream.wordStart(w0);
    final e = stream.units.sublist(u0, stream.wordEnd(w1 - 1));
    final n = e.length, t1 = hyp.length, cols = n + 1;
    final starts = [for (var w = w0; w < w1; w++) stream.wordStart(w) - u0];

    final cost = Float64List((t1 + 1) * cols)..fillRange(0, (t1 + 1) * cols, double.infinity);
    final op = Uint8List((t1 + 1) * cols);
    final from = Int32List((t1 + 1) * cols);

    cost[0] = 0;
    op[0] = _opFree;
    for (var p = 1; p <= n; p++) {
      cost[p] = cost[p - 1] + scorer.indel(e[p - 1]);
      op[p] = _opDel;
    }
    for (var t = 1; t <= t1; t++) {
      final h = hyp[t - 1], row = t * cols, prev = (t - 1) * cols;
      final ins = scorer.indel(h);
      for (var p = 0; p <= n; p++) {
        var best = cost[prev + p] + ins;
        var bestOp = _opIns;
        if (p == 0 && op[prev] == _opFree && t <= config.maxLeadingNoiseUnits) {
          final f = cost[prev] + config.leadingNoiseCost;
          if (f <= best) {
            best = f;
            bestOp = _opFree;
          }
        }
        if (p > 0) {
          final s = cost[prev + p - 1] + scorer.sub(h, e[p - 1]);
          if (s < best) {
            best = s;
            bestOp = _opSub;
          }
        }
        cost[row + p] = best;
        op[row + p] = bestOp;
      }
      // Repeat: from anywhere inside words k .. k+R-1 back to the start of word k.
      for (var k = 0; k < starts.length; k++) {
        final b = starts[k];
        if (b >= n) continue;
        final hi = k + config.repeatBackWords < starts.length ? starts[k + config.repeatBackWords] : n;
        var bestQ = -1;
        var bestC = double.infinity;
        for (var q = b + 1; q <= hi; q++) {
          if (cost[prev + q] < bestC) {
            bestC = cost[prev + q];
            bestQ = q;
          }
        }
        if (bestQ < 0) continue;
        final c = bestC + config.repeatCost + scorer.sub(h, e[b]);
        if (c < cost[row + b + 1]) {
          cost[row + b + 1] = c;
          op[row + b + 1] = _opRep;
          from[row + b + 1] = bestQ;
        }
      }
      for (var p = 1; p <= n; p++) {
        final d = cost[row + p - 1] + scorer.indel(e[p - 1]);
        if (d < cost[row + p]) {
          cost[row + p] = d;
          op[row + p] = _opDel;
        }
      }
    }

    // The reader may stop anywhere: the end is the cheapest expected position.
    // On a tie, prefer the further position (the reader made progress).
    var pEnd = 0;
    for (var p = 1; p <= n; p++) {
      if (cost[t1 * cols + p] <= cost[t1 * cols + pEnd]) pEnd = p;
    }
    if (atPause) {
      for (var k = 0; k < starts.length; k++) {
        final end = k + 1 < starts.length ? starts[k + 1] : n;
        if (starts[k] < pEnd && pEnd < end) {
          pEnd = end;
          break;
        }
      }
    }

    final steps = <_Step>[];
    var t = t1, p = pEnd;
    while (t > 0 || p > 0) {
      final i = t * cols + p, o = op[i];
      if (o == _opFree) {
        if (t == 0) break;
        steps.add(_Step(_opFree, t - 1, -1));
        t--;
      } else if (o == _opSub) {
        steps.add(_Step(_opSub, t - 1, p - 1));
        t--;
        p--;
      } else if (o == _opIns) {
        steps.add(_Step(_opIns, t - 1, p));
        t--;
      } else if (o == _opDel) {
        steps.add(_Step(_opDel, -1, p - 1));
        p--;
      } else {
        steps.add(_Step(_opRep, t - 1, p - 1));
        p = from[i];
        t--;
      }
    }
    final path = steps.reversed.toList();

    return _results(path, hyp, e, starts, w0, u0, pEnd, _tailCost(path, hyp, e));
  }

  double _tailCost(List<_Step> path, List<PUnit> hyp, List<PUnit> e) {
    var total = 0.0, count = 0;
    for (var i = path.length - 1; i >= 0 && count < config.jumpTailUnits; i--) {
      final s = path[i];
      switch (s.op) {
        case _opSub || _opRep:
          total += scorer.sub(hyp[s.hyp], e[s.unit]);
          count++;
        case _opIns:
          total += scorer.indel(hyp[s.hyp]);
          count++;
        case _opDel:
          total += scorer.indel(e[s.unit]);
        case _opFree:
          // Ignored sounds are unexplained: count them fully.
          total += config.consonantIndel;
          count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  AlignmentResult _results(List<_Step> path, List<PUnit> hyp, List<PUnit> e, List<int> starts, int w0,
      int u0, int pEnd, double tail) {
    final n = e.length;
    final nw = starts.length;
    int wordOf(int p) {
      var k = 0;
      while (k + 1 < nw && starts[k + 1] <= p) {
        k++;
      }
      return k;
    }

    // Walk the path. Each repeat starts a new traversal; for every expected
    // unit keep only what happened on its latest traversal.
    var trav = 0;
    final unitOp = List<int>.filled(n, -1);
    final unitHyp = List<int>.filled(n, -1);
    final unitTrav = List<int>.filled(n, -1);
    final wordTrav = List<int>.filled(nw, -1);
    final inserts = <(int gap, int hyp, int trav)>[];
    var lastMatched = -1; // furthest unit matched on the final traversal
    for (final s in path) {
      if (s.op == _opRep) trav++;
      switch (s.op) {
        case _opSub || _opRep || _opDel:
          unitOp[s.unit] = s.op == _opDel ? _opDel : _opSub;
          unitHyp[s.unit] = s.hyp;
          unitTrav[s.unit] = trav;
          wordTrav[wordOf(s.unit)] = trav;
        case _opIns:
          inserts.add((s.unit, s.hyp, trav));
      }
    }
    var curStart = n; // first unit of the final traversal
    for (var p = 0; p < n; p++) {
      if (unitTrav[p] == trav) {
        if (p < curStart) curStart = p;
        if (unitOp[p] == _opSub) lastMatched = p;
      }
    }

    final results = <WordResult>[];
    final extras = <ExtraSpan>[];
    final boundaryIssues = List.generate(nw, (_) => <Issue>[]);
    final trailingHypEnd = List<int>.filled(nw, -1);

    // Insertions at a word boundary: an extra word, or extra sounds on the
    // word before it.
    for (var k = 0; k <= nw; k++) {
      final gap = k < nw ? starts[k] : n;
      final gapTrav = k < nw && wordTrav[k] >= 0 ? wordTrav[k] : trav;
      final here = [for (final i in inserts) if (i.$1 == gap && i.$3 == gapTrav) i.$2];
      if (here.isEmpty) continue;
      final consonants = here.where((h) => hyp[h].kind == UnitKind.consonant).length;
      if (consonants >= config.extraWordMinConsonants) {
        extras.add(ExtraSpan(w0 + k, here.first, here.last + 1));
      } else {
        final target = k > 0 ? k - 1 : 0;
        trailingHypEnd[target] = here.last + 1;
        for (final h in here) {
          boundaryIssues[target].add(scorer.insIssue(hyp[h], u0 + gap));
        }
      }
    }

    for (var k = 0; k < nw; k++) {
      final s = starts[k], end = k + 1 < nw ? starts[k + 1] : n;
      final tr = wordTrav[k];
      final word = w0 + k;
      if (tr < 0 || s == end) {
        results.add(WordResult(word: word, status: s == end ? WordStatus.correct : WordStatus.pending));
        continue;
      }
      var visited = 0, deleted = 0, consonants = 0, deletedConsonants = 0;
      var hs = -1, he = -1;
      final issues = <Issue>[];
      for (var p = s; p < end; p++) {
        if (e[p].kind == UnitKind.consonant) consonants++;
        if (unitTrav[p] != tr) continue;
        visited++;
        if (unitOp[p] == _opDel) {
          deleted++;
          if (e[p].kind == UnitKind.consonant) deletedConsonants++;
          issues.add(scorer.delIssue(e[p], u0 + p));
        } else {
          final h = unitHyp[p];
          if (hs < 0) hs = h;
          he = h + 1;
          issues.addAll(scorer.subIssues(hyp[h], e[p], u0 + p));
        }
      }
      for (final i in inserts) {
        if (i.$1 > s && i.$1 < end && i.$3 == tr) issues.add(scorer.insIssue(hyp[i.$2], u0 + i.$1));
      }
      issues.addAll(boundaryIssues[k]);

      final complete = visited == end - s;
      // Visited on an earlier traversal and not reached again since the
      // reader went back: the result stands but the reader is not past it.
      final aheadOfRepeat = tr < trav && s >= curStart;
      final isPast = complete &&
          !aheadOfRepeat &&
          (tr < trav || (lastMatched >= 0 && lastMatched - (end - 1) >= config.pastMarginUnits));
      final skipped = complete &&
          (deleted == end - s ||
              (consonants > 0 && deleted / (end - s) >= config.skipFraction && deletedConsonants == consonants));

      var finalIssues = issues;
      if (complete && !skipped && _variants.containsKey(word)) {
        final segEnd = trailingHypEnd[k] > he ? trailingHypEnd[k] : he;
        finalIssues = _bestVariant(word, issues, hyp, hs, segEnd, u0 + s);
      }

      final WordStatus status;
      if (!complete) {
        status = WordStatus.pending;
      } else if (skipped) {
        status = WordStatus.skipped;
      } else if (finalIssues.any((i) => i.severity == Severity.high && !i.unsure)) {
        status = WordStatus.wrong;
      } else if (finalIssues.any((i) => i.severity == Severity.high)) {
        status = WordStatus.unsure;
      } else {
        status = WordStatus.correct;
      }
      results.add(WordResult(
        word: word,
        status: status,
        issues: skipped ? const [Issue(IssueType.missingWord)] : finalIssues,
        isPast: isPast,
        hypStart: hs,
        hypEnd: he,
      ));
    }
    return AlignmentResult(words: results, extras: extras, endUnit: u0 + pEnd, tailCostPerUnit: tail);
  }

  /// Re-scores a word against its alternative forms and keeps the form with
  /// the fewest and least severe issues.
  List<Issue> _bestVariant(int word, List<Issue> issues, List<PUnit> hyp, int hs, int he, int base) {
    if (hs < 0) return issues;
    var best = issues;
    var bestScore = _score(issues);
    for (final v in _variants[word]!) {
      final (_, vi) = scorer.compare(v, hyp.sublist(hs, he), base: base);
      final sc = _score(vi);
      if (sc < bestScore) {
        best = vi;
        bestScore = sc;
      }
    }
    return best;
  }

  static int _score(List<Issue> issues) {
    var s = 0;
    for (final i in issues) {
      s += switch (i.severity) { Severity.high => 100, Severity.medium => 10, Severity.low => 1 };
    }
    return s;
  }
}
