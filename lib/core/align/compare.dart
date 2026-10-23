import 'config.dart';
import 'models.dart';
import 'phonetics.dart';
import 'units.dart';

/// Unit-level costs and the issues each edit produces. Shared by the global
/// aligner and the local re-scoring of word variants, so both judge alike.
class UnitScorer {
  const UnitScorer(this.config);

  final TeacherConfig config;

  double indel(PUnit u) => switch (u.kind) {
        UnitKind.consonant => config.consonantIndel,
        UnitKind.shortVowel || UnitKind.longVowel => config.vowelIndel,
        UnitKind.marker => config.markerIndel,
      };

  static bool _isVowel(UnitKind k) => k == UnitKind.shortVowel || k == UnitKind.longVowel;

  double sub(PUnit heard, PUnit expected) {
    if (heard.kind != expected.kind) {
      return _isVowel(heard.kind) && _isVowel(expected.kind) ? config.vowelSub : config.kindSub;
    }
    if (heard.base != expected.base) {
      return heard.kind == UnitKind.consonant ? config.consonantSub : config.vowelSub;
    }
    var cost = 0.0;
    if (heard.isGeminated != expected.isGeminated) cost += config.geminationMismatch;
    if (!_sameDetails(heard, expected) || _lengthIssue(heard, expected) != null) {
      cost += config.detailMismatch;
    }
    return cost;
  }

  static bool _sameDetails(PUnit a, PUnit b) =>
      a.details.length == b.details.length && a.details.containsAll(b.details);

  IssueType? _lengthIssue(PUnit heard, PUnit expected) {
    final diff = (heard.length - expected.length).abs();
    if (expected.kind == UnitKind.longVowel && diff > config.maddLengthTolerance) {
      return IssueType.maddLength;
    }
    if (expected.kind == UnitKind.consonant && heard.isGeminated && expected.isGeminated &&
        (expected.base == 'ن' || expected.base == 'م') && diff >= 2) {
      return IssueType.ghunna;
    }
    return null;
  }

  static IssueType _byKind(UnitKind k, {required IssueType consonant}) => switch (k) {
        UnitKind.consonant => consonant,
        UnitKind.shortVowel => IssueType.harakat,
        UnitKind.longVowel => IssueType.longVowel,
        UnitKind.marker => IssueType.otherTajweed,
      };

  List<Issue> subIssues(PUnit heard, PUnit expected, int expectedIndex) {
    final h = heard.base;
    if (heard.kind != expected.kind) {
      if (_isVowel(heard.kind) && _isVowel(expected.kind)) {
        return [Issue(IssueType.longVowel, expectedUnit: expectedIndex, heard: h)];
      }
      final type = heard.kind == UnitKind.consonant || expected.kind == UnitKind.consonant
          ? IssueType.wrongLetter
          : IssueType.otherTajweed;
      return [Issue(type, expectedUnit: expectedIndex, heard: h)];
    }
    if (heard.base != expected.base) {
      return switch (expected.kind) {
        UnitKind.consonant => [
            Issue(IssueType.wrongLetter,
                expectedUnit: expectedIndex,
                heard: h,
                unsure: config.confusableIsUnsure && isConfusable(h, expected.base)),
          ],
        UnitKind.shortVowel => [Issue(IssueType.harakat, expectedUnit: expectedIndex, heard: h)],
        UnitKind.longVowel => [Issue(IssueType.longVowel, expectedUnit: expectedIndex, heard: h)],
        UnitKind.marker => [Issue(IssueType.otherTajweed, expectedUnit: expectedIndex, heard: h)],
      };
    }
    final issues = <Issue>[];
    if (heard.isGeminated != expected.isGeminated) {
      issues.add(Issue(IssueType.shadda, expectedUnit: expectedIndex, heard: h * heard.length));
    }
    final len = _lengthIssue(heard, expected);
    if (len != null) issues.add(Issue(len, expectedUnit: expectedIndex, heard: h * heard.length));
    final diff = heard.details.difference(expected.details).union(expected.details.difference(heard.details));
    for (final d in diff) {
      final type = switch (d) {
        Detail.ikhfa => IssueType.ikhfa,
        Detail.qalqala => IssueType.qalqala,
        _ => IssueType.otherTajweed,
      };
      issues.add(Issue(type, expectedUnit: expectedIndex, heard: h));
    }
    return issues;
  }

  Issue delIssue(PUnit expected, int expectedIndex) =>
      Issue(_byKind(expected.kind, consonant: IssueType.missingLetter), expectedUnit: expectedIndex);

  Issue insIssue(PUnit heard, int gapIndex) =>
      Issue(_byKind(heard.kind, consonant: IssueType.extraLetter), expectedUnit: gapIndex, heard: heard.base);

  /// Plain edit-distance comparison of two short unit lists (one word).
  /// Returns the cost and the issues, with expected indices offset by [base].
  (double, List<Issue>) compare(List<PUnit> expected, List<PUnit> heard, {int base = 0}) {
    final n = expected.length, m = heard.length;
    final d = List.generate(m + 1, (_) => List<double>.filled(n + 1, 0));
    for (var p = 1; p <= n; p++) {
      d[0][p] = d[0][p - 1] + indel(expected[p - 1]);
    }
    for (var t = 1; t <= m; t++) {
      d[t][0] = d[t - 1][0] + indel(heard[t - 1]);
      for (var p = 1; p <= n; p++) {
        final s = d[t - 1][p - 1] + sub(heard[t - 1], expected[p - 1]);
        final i = d[t - 1][p] + indel(heard[t - 1]);
        final x = d[t][p - 1] + indel(expected[p - 1]);
        d[t][p] = s <= i && s <= x ? s : (i <= x ? i : x);
      }
    }
    final issues = <Issue>[];
    var t = m, p = n;
    while (t > 0 || p > 0) {
      if (t > 0 && p > 0 && d[t][p] == d[t - 1][p - 1] + sub(heard[t - 1], expected[p - 1])) {
        issues.addAll(subIssues(heard[t - 1], expected[p - 1], base + p - 1));
        t--;
        p--;
      } else if (t > 0 && d[t][p] == d[t - 1][p] + indel(heard[t - 1])) {
        issues.add(insIssue(heard[t - 1], base + p));
        t--;
      } else {
        issues.add(delIssue(expected[p - 1], base + p - 1));
        p--;
      }
    }
    return (d[m][n], issues.reversed.toList());
  }
}
