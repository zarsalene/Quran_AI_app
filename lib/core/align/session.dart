import 'aligner.dart';
import 'compare.dart';
import 'config.dart';
import 'models.dart';
import 'units.dart';

enum TeacherMode {
  /// Stop at the first confirmed high-severity mistake.
  strict,

  /// Mark mistakes and keep going.
  gentle,
}

/// Something the UI must react to.
sealed class TeacherEvent {
  const TeacherEvent();
}

/// Strict mode: pause the mic, mark [word] red, play the correct word, and ask
/// the reader to repeat from it. Call [TeacherSession.resumeFrom] next.
class StopEvent extends TeacherEvent {
  const StopEvent(this.word, this.issue);
  final int word;
  final Issue issue;
}

/// A confirmed mistake in gentle mode, or an extra word.
class MistakeEvent extends TeacherEvent {
  const MistakeEvent(this.word, this.issue);
  final int word;
  final Issue issue;
}

/// The reader moved to another place. Words in [skippedFrom, skippedTo) were
/// passed over.
class JumpEvent extends TeacherEvent {
  const JumpEvent(this.toWord, this.skippedFrom, this.skippedTo);
  final int toWord;
  final int skippedFrom;
  final int skippedTo;
}

/// Every word of the range is done.
class FinishedEvent extends TeacherEvent {
  const FinishedEvent({required this.perfect});

  /// True only when every word matched with no issue of any level, nothing was
  /// unsure, and no mistake was confirmed during the session.
  final bool perfect;
}

/// One recitation session over a word range of a surah.
///
/// The stream covers the whole surah, so a jump outside the range is found.
/// Feed the full ASR text of the current attempt with [update] after each
/// decoded chunk.
class TeacherSession {
  TeacherSession({
    required this.stream,
    required this.rangeStart,
    required this.rangeEnd,
    required this.wordAyah,
    this.mode = TeacherMode.strict,
    this.config = const TeacherConfig(),
    Map<int, List<String>>? variants,
    this.windowWords = 40,
    this.trimAfterWords = 8,
  })  : aligner = Aligner(stream, config: config, variants: variants),
        _scorer = UnitScorer(config),
        _windowStart = rangeStart;

  final ExpectedStream stream;

  /// Words [rangeStart, rangeEnd) are the ones the reader chose.
  final int rangeStart;
  final int rangeEnd;

  /// Ayah number of each word in [stream], used to search ±3 ayahs on a jump.
  final List<int> wordAyah;
  final TeacherMode mode;
  final TeacherConfig config;
  final Aligner aligner;
  final UnitScorer _scorer;
  final int windowWords;
  final int trimAfterWords;

  int _windowStart;
  int _hypOffset = 0;
  List<PUnit> _hyp = const [];
  bool _paused = false;
  bool _finished = false;
  /// While the audio is too noisy, the teacher does not judge anything.
  bool noisy = false;

  final Map<int, WordResult> _results = {};
  final Map<String, int> _seen = {};
  final Set<String> _confirmed = {};
  final List<Issue> _mistakes = [];

  /// Latest result of each word that has been reached.
  Map<int, WordResult> get results => Map.unmodifiable(_results);
  List<Issue> get confirmedMistakes => List.unmodifiable(_mistakes);
  bool get isPaused => _paused;
  bool get isFinished => _finished;


  /// Starts a new attempt at [word] after a stop or a jump. The ASR stream
  /// must be reset too, because [update] expects text of the new attempt.
  void resumeFrom(int word) {
    _windowStart = word;
    _hypOffset = 0;
    _hyp = const [];
    _paused = false;
    _seen.clear();
    for (final k in _results.keys.where((k) => k >= word).toList()) {
      _results.remove(k);
    }
  }

  /// [asrText] is the full phoneme output of the current attempt.
  /// [atPause] is true while the reader is silent (from the VAD).
  List<TeacherEvent> update(String asrText, {bool atPause = false}) {
    if (_paused || _finished || noisy) return const [];
    final all = toUnits(asrText);
    if (all.length <= _hypOffset) return const [];
    _hyp = all.sublist(_hypOffset);

    final windowEnd = (_firstOpen() + windowWords).clamp(0, stream.wordCount);
    final r = aligner.align(_hyp, fromWord: _windowStart, toWord: windowEnd, atPause: atPause);

    final jump = _checkJump(r);
    if (jump != null) return [jump];

    for (final w in r.words) {
      if (w.status != WordStatus.pending) _results[w.word] = w;
    }
    final events = <TeacherEvent>[];
    for (final w in r.words) {
      if (w.word < rangeStart || w.word >= rangeEnd) continue;
      final e = _judgeWord(w);
      if (e != null) {
        events.add(e);
        if (e is StopEvent) return events;
      }
    }
    for (final x in r.extras) {
      if (x.beforeWord <= rangeStart || x.beforeWord > rangeEnd) continue;
      final issue = Issue(IssueType.extraWord, expectedUnit: stream.wordStart(x.beforeWord.clamp(0, stream.wordCount - 1)));
      final e = _confirm('x${x.beforeWord}', x.beforeWord, issue, past: x.hypEnd < _hyp.length - config.pastMarginUnits);
      if (e != null) {
        events.add(e);
        if (e is StopEvent) return events;
      }
    }
    _trim(r);
    if (_rangeDone()) {
      // The reader is never "past" the last word, so confirm what is left now.
      for (var w = rangeStart; w < rangeEnd; w++) {
        final e = _judgeWord(_results[w]!, forcePast: true);
        if (e != null) {
          events.add(e);
          if (e is StopEvent) return events;
        }
      }
      _finished = true;
      events.add(FinishedEvent(perfect: _isPerfect()));
    }
    return events;
  }

  TeacherEvent? _judgeWord(WordResult w, {bool forcePast = false}) {
    final complete = w.status != WordStatus.pending;
    if (!complete) return null;
    for (final issue in w.issues) {
      if (issue.severity != Severity.high || issue.unsure) continue;
      final e = _confirm('w${w.word}:${issue.signature}', w.word, issue, past: forcePast || w.isPast);
      if (e != null) return e;
    }
    return null;
  }

  /// A mistake counts once it showed in [TeacherConfig.confirmEvaluations]
  /// evaluations in a row, or once the reader is past it.
  TeacherEvent? _confirm(String key, int word, Issue issue, {required bool past}) {
    if (_confirmed.contains(key)) return null;
    final n = (_seen[key] ?? 0) + 1;
    _seen[key] = n;
    if (!past && n < config.confirmEvaluations) return null;
    _confirmed.add(key);
    _mistakes.add(issue);
    if (mode == TeacherMode.strict) {
      _paused = true;
      return StopEvent(word, issue);
    }
    return MistakeEvent(word, issue);
  }

  int _firstOpen() {
    for (var w = _windowStart; w < stream.wordCount; w++) {
      final r = _results[w];
      if (r == null || !r.isPast) return w;
    }
    return stream.wordCount;
  }

  /// Drops words that are well behind the reader, so each update stays fast
  /// on long ranges. Keeps [TeacherConfig.repeatBackWords] words for repeats.
  void _trim(AlignmentResult r) {
    final open = _firstOpen();
    final newStart = open - config.repeatBackWords;
    if (newStart - _windowStart < trimAfterWords) return;
    final at = r.words.where((w) => w.word >= newStart && w.hypStart >= 0).firstOrNull;
    if (at == null) return;
    _hypOffset += at.hypStart;
    _hyp = _hyp.sublist(at.hypStart);
    _windowStart = at.word;
  }

  TeacherEvent? _checkJump(AlignmentResult r) {
    if (_hyp.length < config.jumpTailUnits || r.tailCostPerUnit < config.jumpTailCost) return null;
    final tail = _hyp.sublist(_hyp.length - config.jumpTailUnits);
    final here = stream.unitWord[(r.endUnit).clamp(0, stream.units.length - 1)];
    final ayah = wordAyah[here];
    int firstWordOf(int a) => wordAyah.indexWhere((x) => x >= a);
    int endWordOf(int a) {
      final i = wordAyah.indexWhere((x) => x > a);
      return i < 0 ? stream.wordCount : i;
    }

    final near = _search(tail, firstWordOf(ayah - 3).clamp(0, stream.wordCount), endWordOf(ayah + 3));
    final hit = near ?? _search(tail, 0, stream.wordCount);
    if (hit == null) return null;
    final (startWord, endWord, tailFrom) = hit;
    // Matching where we already are is not a jump: it is a bad stretch.
    if (startWord <= here + 1 && endWord >= here - 1) return null;

    // Forward jump: the words not finished before the target were passed over.
    // Backward jump: nothing was passed over.
    var from = startWord;
    if (startWord > here) {
      from = _windowStart;
      while (from < startWord && _wasRead(_results[from])) {
        from++;
      }
    }
    final to = startWord;
    for (var w = from; w < to; w++) {
      if (w >= rangeStart && w < rangeEnd && !(_results[w]?.isPast ?? false)) {
        _results[w] = WordResult(word: w, status: WordStatus.jumped, issues: const [Issue(IssueType.missingWord)]);
      }
    }
    // Restart alignment at the jump target with the tail as the new attempt.
    _windowStart = startWord;
    _hypOffset += _hyp.length - config.jumpTailUnits + tailFrom;
    _hyp = tail.sublist(tailFrom);
    _seen.clear();
    if (from < to) _mistakes.add(const Issue(IssueType.missingWord));
    if (mode == TeacherMode.strict && from < to && from < rangeEnd && to > rangeStart) _paused = true;
    return JumpEvent(startWord, from, to);
  }

  /// Finds where [tail] fits best inside words [w0, w1).
  ///
  /// Returns the word where the new reading starts, the word where it ends,
  /// and the index in [tail] where the new reading starts (the first units of
  /// the tail may still be from before the jump). Null if nothing fits.
  (int, int, int)? _search(List<PUnit> tail, int w0, int w1) {
    if (w1 <= w0) return null;
    final u0 = stream.wordStart(w0), u1 = stream.wordEnd(w1 - 1);
    final e = stream.units.sublist(u0, u1);
    final n = e.length, m = tail.length, cols = n + 1;
    // Semi-global: the whole tail is used; the expected text may start and
    // end anywhere. The matrix is m x n with m = jumpTailUnits (small).
    final d = List<double>.filled((m + 1) * cols, 0);
    for (var t = 1; t <= m; t++) {
      final row = t * cols, prev = (t - 1) * cols;
      d[row] = d[prev] + _scorer.indel(tail[t - 1]);
      for (var p = 1; p <= n; p++) {
        final s = d[prev + p - 1] + _scorer.sub(tail[t - 1], e[p - 1]);
        final i = d[prev + p] + _scorer.indel(tail[t - 1]);
        final x = d[row + p - 1] + _scorer.indel(e[p - 1]);
        d[row + p] = s <= i && s <= x ? s : (i <= x ? i : x);
      }
    }
    var best = 1;
    for (var p = 2; p <= n; p++) {
      if (d[m * cols + p] < d[m * cols + best]) best = p;
    }
    if (d[m * cols + best] / m > config.jumpAcceptCost) return null;

    // Trace back. Keep, for each tail unit, the expected unit it matched
    // exactly (or -1) and the path cost spent from that unit to the end.
    final matched = List<int>.filled(m, -1);
    final costFrom = List<double>.filled(m + 1, 0);
    var t = m, p = best;
    final total = d[m * cols + best];
    while (t > 0) {
      final here = d[t * cols + p];
      if (p > 0 && here == d[(t - 1) * cols + p - 1] + _scorer.sub(tail[t - 1], e[p - 1])) {
        if (_scorer.sub(tail[t - 1], e[p - 1]) == 0) matched[t - 1] = p - 1;
        t--;
        p--;
      } else if (p > 0 && here == d[t * cols + p - 1] + _scorer.indel(e[p - 1])) {
        p--;
        continue;
      } else {
        t--;
      }
      costFrom[t] = total - d[t * cols + p];
    }
    // The new reading starts at the first run of [_jumpRun] exact matches in
    // a row after which the rest of the tail fits the accept threshold. One
    // matching vowel left over from before the jump must not set the target.
    for (var i = 0; i + _jumpRun <= m; i++) {
      var run = true;
      for (var k = 0; k < _jumpRun; k++) {
        if (matched[i + k] < 0 || matched[i + k] != matched[i] + k) run = false;
      }
      if (run && costFrom[i] / (m - i) <= config.jumpAcceptCost) {
        return (stream.unitWord[u0 + matched[i]], stream.unitWord[u0 + best - 1], i);
      }
    }
    return null;
  }

  static const _jumpRun = 3;

  static bool _wasRead(WordResult? r) =>
      r != null && r.status != WordStatus.pending && r.status != WordStatus.skipped;

  bool _rangeDone() {
    for (var w = rangeStart; w < rangeEnd; w++) {
      final r = _results[w];
      if (r == null || r.status == WordStatus.pending) return false;
    }
    return true;
  }

  bool _isPerfect() {
    if (_mistakes.isNotEmpty) return false;
    for (var w = rangeStart; w < rangeEnd; w++) {
      final r = _results[w]!;
      if (r.status != WordStatus.correct || r.issues.isNotEmpty) return false;
    }
    return true;
  }
}
