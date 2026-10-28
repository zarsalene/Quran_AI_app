import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_catalog.dart';

/// The surah audio is not on the phone.
class AudioNotAvailable implements Exception {
  const AudioNotAvailable(this.surah);
  final int surah;
}

/// Plays the recitation: an ayah range with repeats, or one word.
///
/// Each surah is one file. The player follows the position against the ayah
/// and word timings to repeat, move on, stop at the range end, and highlight
/// the word being recited.
class RecitationPlayer extends ChangeNotifier {
  RecitationPlayer(this._catalog, {AudioPlayer? player}) : _p = player ?? AudioPlayer() {
    _subs.add(_p.createPositionStream(
      steps: 10000,
      minPeriod: const Duration(milliseconds: 30),
      maxPeriod: const Duration(milliseconds: 80),
    ).listen(_onPosition));
    _subs.add(_p.playerStateStream.listen(_onState));
  }

  AudioCatalog _catalog;
  final AudioPlayer _p;

  /// The reciter used for ayah ranges.
  AudioCatalog get catalog => _catalog;

  /// Changes the reciter. Stops what is playing.
  Future<void> setCatalog(AudioCatalog c) async {
    if (c == _catalog) return;
    await stop();
    _catalog = c;
    _loadedSurah = null;
    notifyListeners();
  }

  // The catalog of the loaded file (a word can come from another reciter).
  AudioCatalog? _loadedCatalog;

  /// True while one word plays (tap on a word, or the teacher's model answer).
  bool wordPlaying = false;
  final List<StreamSubscription<Object?>> _subs = [];

  // What is loaded.
  int? _loadedSurah;
  bool _clipped = false;

  // Range play.
  int? surah;
  int? ayah;
  int? word;
  int _from = 1, _to = 1;
  int _played = 0;
  bool _rangeActive = false;
  Completer<void>? _rangeDone;

  /// Times each ayah is played before the next one (1 = once).
  int repeatEach = 1;

  /// Start the range again at its end.
  bool loopRange = false;
  double speed = 1.0;

  bool get playing => _p.playing;
  bool get isRangeActive => _rangeActive;
  int get rangeFrom => _from;
  int get rangeTo => _to;

  /// Number of times the current ayah has played, from 1.
  int get repeatNumber => _played + 1;

  static const _sourceOptions = ProgressiveAudioSourceOptions(
    androidExtractorOptions: AndroidExtractorOptions(mp3Flags: AndroidExtractorOptions.flagMp3EnableIndexSeeking),
  );

  Future<void> _load(int s, {AudioCatalog? from}) async {
    final cat = from ?? _catalog;
    if (_loadedSurah == s && _loadedCatalog == cat && !_clipped) return;
    final source = switch (cat.location(s)) {
      BundledAudio(:final asset) => ProgressiveAudioSource(Uri.parse('asset:///$asset'), options: _sourceOptions),
      DownloadedAudio(:final path) => ProgressiveAudioSource(Uri.file(path), options: _sourceOptions),
      MissingAudio() => throw AudioNotAvailable(s),
    };
    await _p.setAudioSource(source, preload: true);
    _loadedSurah = s;
    _loadedCatalog = cat;
    _clipped = false;
  }

  /// Plays ayahs [from]..[to] of surah [s] with the current repeat settings.
  /// The future completes when the range has finished or playback stopped.
  Future<void> playRange(int s, int from, int to) async {
    await stop();
    await _load(s);
    surah = s;
    _from = from;
    _to = to;
    ayah = from;
    word = null;
    _played = 0;
    _rangeActive = true;
    final done = _rangeDone = Completer<void>();
    await _p.setSpeed(speed);
    await _p.seek(Duration(milliseconds: _catalog.surah(s).ayah(from).start));
    notifyListeners();
    unawaited(_p.play());
    return done.future;
  }

  /// Plays one ayah [times] times, ignoring the repeat settings.
  Future<void> playAyahTimes(int s, int a, int times) async {
    final keepRepeat = repeatEach, keepLoop = loopRange;
    repeatEach = times;
    loopRange = false;
    try {
      await playRange(s, a, a);
    } finally {
      repeatEach = keepRepeat;
      loopRange = keepLoop;
    }
  }

  /// Plays one word (0-based index in the ayah): the teacher's model answer,
  /// or a word the reader tapped. [from] picks the reciter (default: current).
  Future<void> playWord(int s, int a, int w, {AudioCatalog? from}) async {
    await stop();
    final cat = from ?? _catalog;
    await _load(s, from: cat);
    final (start, end) = cat.surah(s).ayah(a).wordSpan(w);
    surah = s;
    ayah = a;
    word = w;
    wordPlaying = true;
    await _p.setSpeed(1.0);
    // A little before and after, so the start and end are not cut.
    await _p.setClip(
      start: Duration(milliseconds: (start - 60).clamp(0, 1 << 31)),
      end: Duration(milliseconds: end + 120),
    );
    _clipped = true;
    notifyListeners();
    await _p.play();
    word = null;
    wordPlaying = false;
    notifyListeners();
  }

  Future<void> pause() async {
    await _p.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    if (_clipped || _loadedSurah == null) return;
    unawaited(_p.play());
    notifyListeners();
  }

  Future<void> stop() async {
    _endRange();
    wordPlaying = false;
    if (_clipped) {
      await _p.stop();
      _loadedSurah = null;
      _clipped = false;
    } else {
      await _p.pause();
    }
    word = null;
    notifyListeners();
  }

  void setSpeed(double v) {
    speed = v;
    if (_rangeActive) _p.setSpeed(v);
    notifyListeners();
  }

  void setRepeat(int n) {
    repeatEach = n;
    notifyListeners();
  }

  void setLoop(bool v) {
    loopRange = v;
    notifyListeners();
  }

  /// Moves to ayah [a] of the current range.
  Future<void> jumpTo(int a) async {
    final s = surah;
    if (s == null || !_rangeActive) return;
    ayah = a;
    _played = 0;
    await _p.seek(Duration(milliseconds: _catalog.surah(s).ayah(a).start));
    notifyListeners();
  }

  void _endRange() {
    _rangeActive = false;
    final done = _rangeDone;
    _rangeDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  bool _seeking = false;

  void _onPosition(Duration pos) {
    final s = surah, a = ayah;
    if (!_rangeActive || s == null || a == null || _seeking || !_p.playing) return;
    final ms = pos.inMilliseconds;
    final timing = _catalog.surah(s).ayah(a);
    if (ms < timing.to) {
      final w = timing.wordAt(ms);
      if (w != word) {
        word = w;
        notifyListeners();
      }
      return;
    }
    // End of the ayah.
    _played++;
    if (_played < repeatEach) {
      _seekTo(timing.start);
    } else if (a < _to) {
      _played = 0;
      ayah = a + 1;
      final next = _catalog.surah(s).ayah(a + 1);
      // The next ayah usually starts where this one ends. Seek only if not.
      if ((next.start - ms).abs() > 300) _seekTo(next.start);
    } else if (loopRange) {
      _played = 0;
      ayah = _from;
      _seekTo(_catalog.surah(s).ayah(_from).start);
    } else {
      _p.pause();
      ayah = null;
      word = null;
      _endRange();
    }
    notifyListeners();
  }

  Future<void> _seekTo(int ms) async {
    _seeking = true;
    try {
      await _p.seek(Duration(milliseconds: ms));
    } finally {
      _seeking = false;
    }
  }

  void _onState(PlayerState st) {
    if (st.processingState == ProcessingState.completed && _rangeActive) {
      // The file ended (last ayah of the surah).
      final s = surah;
      if (loopRange && s != null) {
        _played = 0;
        ayah = _from;
        _seekTo(_catalog.surah(s).ayah(_from).start).then((_) => _p.play());
        return;
      }
      _played++;
      if (_played < repeatEach && s != null && ayah != null) {
        _seekTo(_catalog.surah(s).ayah(ayah!).start).then((_) => _p.play());
        return;
      }
      ayah = null;
      word = null;
      _endRange();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _endRange();
    _p.dispose();
    super.dispose();
  }
}
