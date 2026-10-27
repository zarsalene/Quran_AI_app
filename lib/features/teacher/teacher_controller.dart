import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/align/models.dart';
import '../../core/align/session.dart';
import '../../core/align/units.dart';
import '../../core/asr/asr_engine.dart';
import '../../core/asr/asr_worker.dart';
import '../../core/quran/quran_repo.dart';

enum TeacherPhase { loading, ready, listening, stopped, finished, error }

/// The words of one surah laid out for the teacher.
class SurahLayout {
  SurahLayout._(this.surah, this.basmalaWords, this.words, this.wordAyah, this.variants, this._ayahStart);

  /// Builds the expected stream: the basmala first (optional, not judged)
  /// when the surah has one above it, then every word of the surah.
  factory SurahLayout(QSurah surah, QSurah fatiha) {
    final basmala = surah.basmala == null ? const <QWord>[] : fatiha.ayahs.first.words;
    final words = <QWord>[...basmala];
    final wordAyah = List<int>.filled(basmala.length, 0, growable: true);
    final ayahStart = <int>[];
    for (final a in surah.ayahs) {
      ayahStart.add(words.length);
      words.addAll(a.words);
      wordAyah.addAll(List.filled(a.words.length, a.number));
    }
    final variants = <int, List<String>>{
      for (var i = 0; i < words.length; i++)
        if (words[i].variants.isNotEmpty) i: words[i].variants,
    };
    return SurahLayout._(surah, basmala.length, words, wordAyah, variants, ayahStart);
  }

  final QSurah surah;
  final int basmalaWords;
  final List<QWord> words;
  final List<int> wordAyah;
  final Map<int, List<String>> variants;
  final List<int> _ayahStart;

  int get firstWord => basmalaWords;
  int get endWord => words.length;
  int get ayahCount => surah.ayahs.length;

  /// Index of the first word of ayah [a].
  int ayahFirstWord(int a) => _ayahStart[a - 1];

  /// Index after the last word of ayah [a].
  int ayahEndWord(int a) => a < ayahCount ? _ayahStart[a] : words.length;

  /// Position of word [i] inside its ayah (0-based), or -1 for the basmala.
  int wordInAyah(int i) => wordAyah[i] == 0 ? -1 : i - ayahFirstWord(wordAyah[i]);
}

/// Runs recitations of an ayah range: mic → ASR → teacher session → UI state.
class TeacherController extends ChangeNotifier {
  TeacherController(this.layout, {this.mode = TeacherMode.strict, this.fromAyah = 1, int? toAyah, this.hidden = false})
      : toAyah = toAyah ?? layout.ayahCount;

  final SurahLayout layout;
  TeacherMode mode;
  int fromAyah;
  int toAyah;

  /// Memorization: words stay hidden until recited correctly.
  bool hidden;

  /// Called once per attempt for each ayah the reader finished.
  void Function(int ayah)? onAyahDone;

  TeacherPhase phase = TeacherPhase.loading;
  String? error;

  /// The word to recite again from, after a stop.
  int? stopWord;
  Issue? stopIssue;
  bool stopWasJump = false;
  bool noisy = false;
  bool perfect = false;

  /// Confirmed mistakes of the attempt (stops included).
  int mistakes = 0;

  /// Hidden words shown on request (each one is a hint).
  final Set<int> peeked = {};

  AsrEngine? _engine;
  StreamSubscription<AsrUpdate>? _sub;
  late TeacherSession _session = _newSession();
  int _attempt = 0;
  final Set<int> _doneAyahs = {};

  /// Silence that counts as a pause, so a half-heard word is judged.
  static const pauseMs = 600;

  Map<int, WordResult> get results => _session.results;
  int get rangeStart => layout.ayahFirstWord(fromAyah);
  int get rangeEnd => layout.ayahEndWord(toAyah);
  int get hints => peeked.length;

  /// The basmala may be recited before ayah 1 only.
  bool get showsBasmala => fromAyah == 1 && layout.basmalaWords > 0;

  TeacherSession _newSession() => TeacherSession(
        stream: ExpectedStream([for (final w in layout.words) w.phonemes]),
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        startWord: fromAyah == 1 ? 0 : rangeStart,
        wordAyah: layout.wordAyah,
        mode: mode,
        variants: layout.variants,
      );

  Future<void> init() async {
    try {
      final engine = await AsrEngine.start();
      _engine = engine;
      _sub = engine.updates.listen(_onUpdate);
      phase = TeacherPhase.ready;
    } catch (e) {
      error = '$e';
      phase = TeacherPhase.error;
    }
    notifyListeners();
  }

  Future<bool> micAllowed() async => await _engine?.micAllowed() ?? false;
  Future<bool> requestMic() async => await _engine?.requestMic() ?? false;

  /// Chooses another range (memorization moves ayah by ayah). Not while listening.
  Future<void> setRange(int from, int to, {bool? hidden, TeacherMode? mode}) async {
    await stopListening();
    fromAyah = from;
    toAyah = to;
    this.hidden = hidden ?? this.hidden;
    this.mode = mode ?? this.mode;
    _reset();
    if (phase != TeacherPhase.error && phase != TeacherPhase.loading) phase = TeacherPhase.ready;
    notifyListeners();
  }

  void _reset() {
    _session = _newSession();
    stopWord = null;
    stopIssue = null;
    perfect = false;
    mistakes = 0;
    peeked.clear();
    _doneAyahs.clear();
  }

  /// Starts (or restarts) the whole range.
  Future<void> start() async {
    _reset();
    await _listen();
  }

  /// After a stop: recite again from [stopWord].
  Future<void> resume() async {
    final w = stopWord;
    if (w == null) return;
    _session.resumeFrom(w);
    stopWord = null;
    stopIssue = null;
    await _listen();
  }

  void setMode(TeacherMode m) {
    if (phase == TeacherPhase.listening) return;
    mode = m;
    _session = _newSession();
    notifyListeners();
  }

  /// Shows the next hidden word (a hint).
  void peek() {
    for (var w = rangeStart; w < rangeEnd; w++) {
      if (!isVisible(w)) {
        peeked.add(w);
        notifyListeners();
        return;
      }
    }
  }

  /// Whether word [i] is shown in memorization mode.
  bool isVisible(int i) {
    if (!hidden || peeked.contains(i) || stopWord == i || phase == TeacherPhase.finished) return true;
    final r = results[i];
    return r != null && r.status != WordStatus.pending && r.status != WordStatus.jumped;
  }

  Future<void> _listen() async {
    final engine = _engine;
    if (engine == null) return;
    _attempt++;
    engine.reset(_attempt);
    await engine.listen();
    phase = TeacherPhase.listening;
    notifyListeners();
  }

  Future<void> stopListening() async {
    await _engine?.pause();
    if (phase == TeacherPhase.listening) phase = TeacherPhase.ready;
    notifyListeners();
  }

  void _onUpdate(AsrUpdate u) {
    if (u.attempt != _attempt || phase != TeacherPhase.listening) return;
    noisy = u.noisy;
    _session.noisy = u.noisy;
    final events = _session.update(u.text, atPause: !u.speaking && u.silenceMs >= pauseMs);
    for (final e in events) {
      switch (e) {
        case StopEvent(:final word, :final issue):
          _stop(word, issue, jump: false);
          return;
        case JumpEvent(:final skippedFrom, :final skippedTo):
          if (mode == TeacherMode.strict && skippedFrom < skippedTo) {
            _stop(skippedFrom, const Issue(IssueType.missingWord), jump: true);
            return;
          }
        case MistakeEvent():
          break;
        case FinishedEvent(perfect: final p):
          perfect = p && peeked.isEmpty;
          mistakes = _session.confirmedMistakes.length;
          phase = TeacherPhase.finished;
          unawaited(_engine?.pause());
      }
    }
    _checkAyahsDone();
    notifyListeners();
  }

  void _checkAyahsDone() {
    for (var a = fromAyah; a <= toAyah; a++) {
      if (_doneAyahs.contains(a)) continue;
      final end = layout.ayahEndWord(a);
      var done = true;
      for (var w = layout.ayahFirstWord(a); w < end && done; w++) {
        final r = results[w];
        done = r != null && r.status != WordStatus.pending;
      }
      // The ayah is done once the reader is on the next one, or at the end.
      if (done && (a == toAyah ? phase == TeacherPhase.finished : results.containsKey(end))) {
        _doneAyahs.add(a);
        onAyahDone?.call(a);
      }
    }
  }

  void _stop(int word, Issue issue, {required bool jump}) {
    stopWord = word;
    stopIssue = issue;
    stopWasJump = jump;
    mistakes = _session.confirmedMistakes.length;
    phase = TeacherPhase.stopped;
    HapticFeedback.mediumImpact();
    unawaited(_engine?.pause());
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine?.dispose();
    super.dispose();
  }
}
