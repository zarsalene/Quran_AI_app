import 'dart:math' as math;
import 'dart:typed_data';

/// Converts little-endian 16-bit PCM bytes from the mic to samples in [-1, 1].
/// An odd trailing byte is ignored.
Float32List pcm16ToFloat(Uint8List bytes) {
  final n = bytes.length ~/ 2;
  final data = ByteData.sublistView(bytes, 0, n * 2);
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    out[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return out;
}

/// Root-mean-square level of [samples] in dBFS (0 is full scale).
double rmsDbfs(Float32List samples) {
  if (samples.isEmpty) return -120;
  var sum = 0.0;
  for (final s in samples) {
    sum += s * s;
  }
  final rms = math.sqrt(sum / samples.length);
  return rms <= 1e-6 ? -120 : 20 * math.log(rms) / math.ln10;
}

/// Tracks the background noise level from audio the VAD marks as silence, and
/// the speech level from audio it marks as speech.
///
/// The teacher must not judge a recitation it cannot hear well, so [isNoisy]
/// is true when the background is loud or speech is not clearly above it.
/// Thresholds are starting values for tool/eval to tune.
class NoiseMeter {
  NoiseMeter({this.maxNoiseDbfs = -38, this.minSnrDb = 12, this.smoothing = 0.1});

  final double maxNoiseDbfs;
  final double minSnrDb;

  /// Weight of each new frame in the running averages.
  final double smoothing;

  double? _noise;
  double? _speech;

  double? get noiseDbfs => _noise;
  double? get speechDbfs => _speech;

  void add(Float32List frame, {required bool speech}) {
    final level = rmsDbfs(frame);
    if (speech) {
      _speech = _speech == null ? level : _speech! + smoothing * (level - _speech!);
    } else {
      _noise = _noise == null ? level : _noise! + smoothing * (level - _noise!);
    }
  }

  bool get isNoisy {
    final noise = _noise;
    if (noise == null) return false;
    if (noise > maxNoiseDbfs) return true;
    final speech = _speech;
    return speech != null && speech - noise < minSnrDb;
  }

  void reset() {
    _noise = null;
    _speech = null;
  }
}
