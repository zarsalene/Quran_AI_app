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
  SurahLayout._(this.surah, this.basmalaWords, this.words, this.wordAyah, this.variants);

  /// Builds the expected stream: the basmala first (optional, not judged)
  /// when the surah has one above it, then every word of the surah.
  factory SurahLayout(QSurah surah, QSurah fatiha) {
    final basmala = surah.basmala == null ? const <QWord>[] : fatiha.ayahs.first.words;
    final words = <QWord>[...basmala];
    final wordAyah = List<int>.filled(basmala.length, 0, growable: true);
    for (final a in surah.ayahs) {
      words.addAll(a.words);
      wordAyah.addAll(List.filled(a.words.length, a.number));
    }
    final variants = <int, List<String>>{
      for (var i = 0; i < words.length; i++)
        if (words[i].variants.isNotEmpty) i: words[i].variants,
    };
    return SurahLayout._(surah, basmala.length, words, wordAyah, variants);
  }

  final QSurah surah;
  final int basmalaWords;
  final List<QWord> words;
  final List<int> wordAyah;
  final Map<int, List<String>> variants;

  int get firstWord => basmalaWords;
  int get endWord => words.length;
}

/// Runs one recitation of a surah: mic → ASR → teacher session → UI state.
class TeacherController extends ChangeNotifier {
  TeacherController(this.layout, {this.mode = TeacherMode.strict});

  final SurahLayout layout;
  TeacherMode mode;

  TeacherPhase phase = TeacherPhase.loading;
  String? error;

  /// The word to recite again from, after a stop.
  int? stopWord;
  Issue? stopIssue;
  bool stopWasJump = false;
  bool noisy = false;
  bool perfect = false;
  int mistakes = 0;

  AsrEngine? _engine;
  StreamSubscription<AsrUpdate>? _sub;
  late TeacherSession _session = _newSession();
  int _attempt = 0;

  /// Silence that counts as a pause, so a half-heard word is judged.
  static const pauseMs = 600;

  Map<int, WordResult> get results => _session.results;

  TeacherSession _newSession() => TeacherSession(
        stream: ExpectedStream([for (final w in layout.words) w.phonemes]),
        rangeStart: layout.firstWord,
        rangeEnd: layout.endWord,
        startWord: 0,
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

  /// Starts (or restarts) the whole surah.
  Future<void> start() async {
    _session = _newSession();
    stopWord = null;
    stopIssue = null;
    perfect = false;
    mistakes = 0;
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
    notifyListeners();
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
          perfect = p;
          mistakes = _session.confirmedMistakes.length;
          phase = TeacherPhase.finished;
          unawaited(_engine?.pause());
      }
    }
    notifyListeners();
  }

  void _stop(int word, Issue issue, {required bool jump}) {
    stopWord = word;
    stopIssue = issue;
    stopWasJump = jump;
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
