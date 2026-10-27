import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'asr_worker.dart';

/// Mic + on-device ASR. Audio never leaves the phone.
class AsrEngine {
  AsrEngine._(this._worker);

  final AsrWorker _worker;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _mic;

  Stream<AsrUpdate> get updates => _worker.updates;

  static const _assets = {
    'model': 'assets/models/asr.int8.onnx',
    'tokens': 'assets/models/tokens.txt',
    'vad': 'assets/models/silero_vad.onnx',
  };

  /// Copies the bundled models to app storage once, then starts the worker.
  static Future<AsrEngine> start() async {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/models');
    await dir.create(recursive: true);
    final paths = <String, String>{};
    for (final MapEntry(:key, :value) in _assets.entries) {
      final file = File('${dir.path}/${value.split('/').last}');
      final data = await rootBundle.load(value);
      if (!await file.exists() || await file.length() != data.lengthInBytes) {
        await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      }
      paths[key] = file.path;
    }
    final worker = await AsrWorker.spawn(AsrPaths(model: paths['model']!, tokens: paths['tokens']!, vad: paths['vad']!));
    return AsrEngine._(worker);
  }

  /// True if the mic is already allowed. Never shows the system prompt.
  Future<bool> micAllowed() => _recorder.hasPermission(request: false);

  /// Shows the system prompt if needed. Explain why before calling this.
  Future<bool> requestMic() => _recorder.hasPermission();

  /// Starts listening. Call [reset] first to begin a new attempt.
  Future<void> listen() async {
    if (_mic != null) return;
    final audio = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      echoCancel: false,
      noiseSuppress: false,
      autoGain: true,
    ));
    _mic = audio.listen(_worker.addAudio);
  }

  /// Stops the mic (Strict mode pauses it at a mistake).
  Future<void> pause() async {
    await _mic?.cancel();
    _mic = null;
    await _recorder.stop();
  }

  /// Starts a new attempt. Updates carry this number.
  void reset(int attempt) => _worker.reset(attempt);

  Future<void> dispose() async {
    await pause();
    await _recorder.dispose();
    _worker.dispose();
  }
}
