import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as so;

import 'pcm.dart';

/// Paths of the model files on disk (sherpa-onnx cannot read Flutter assets).
class AsrPaths {
  const AsrPaths({required this.model, required this.tokens, required this.vad});
  final String model;
  final String tokens;
  final String vad;
}

/// One update from the worker after a block of audio.
class AsrUpdate {
  const AsrUpdate({
    required this.text,
    required this.speaking,
    required this.silenceMs,
    required this.noisy,
    required this.decodeMs,
  });

  /// Full phoneme text of the current attempt (since the last reset).
  final String text;

  /// The VAD hears speech in the latest audio.
  final bool speaking;

  /// Milliseconds of silence since speech last stopped.
  final int silenceMs;
  final bool noisy;

  /// Time spent decoding this block, for the latency budget.
  final int decodeMs;
}

/// Messages to the worker.
sealed class _Cmd {
  const _Cmd();
}

class _Audio extends _Cmd {
  const _Audio(this.pcm16);
  final Uint8List pcm16;
}

class _Reset extends _Cmd {
  const _Reset();
}

class _Stop extends _Cmd {
  const _Stop();
}

/// Runs in its own isolate so decoding never blocks the UI thread.
class AsrWorker {
  AsrWorker._(this._isolate, this._send, this.updates);

  final Isolate _isolate;
  final SendPort _send;

  /// One update per audio block.
  final Stream<AsrUpdate> updates;

  static Future<AsrWorker> spawn(AsrPaths paths, {int numThreads = 2}) async {
    final fromWorker = ReceivePort();
    final isolate = await Isolate.spawn(_main, (fromWorker.sendPort, paths, numThreads));
    final stream = fromWorker.asBroadcastStream();
    final first = await stream.first;
    if (first is String) {
      fromWorker.close();
      throw StateError('ASR failed to start: $first');
    }
    return AsrWorker._(isolate, first as SendPort, stream.where((m) => m is AsrUpdate).cast<AsrUpdate>());
  }

  /// Raw mic bytes: 16 kHz, mono, 16-bit little-endian PCM.
  void addAudio(Uint8List pcm16) => _send.send(_Audio(pcm16));

  /// Starts a new attempt: the next updates contain only new speech.
  void reset() => _send.send(const _Reset());

  void dispose() {
    _send.send(const _Stop());
    _isolate.kill(priority: Isolate.beforeNextEvent);
  }

  static void _main((SendPort, AsrPaths, int) args) {
    final (out, paths, threads) = args;
    final so.OnlineRecognizer recognizer;
    final so.VoiceActivityDetector vad;
    try {
      so.initBindings();
      recognizer = so.OnlineRecognizer(so.OnlineRecognizerConfig(
        model: so.OnlineModelConfig(
          zipformer2Ctc: so.OnlineZipformer2CtcModelConfig(model: paths.model),
          tokens: paths.tokens,
          numThreads: threads,
          debug: false,
        ),
        // The session decides pauses from the VAD; no endpoint resets here.
        enableEndpoint: false,
      ));
      vad = so.VoiceActivityDetector(
        config: so.VadModelConfig(
          sileroVad: so.SileroVadModelConfig(model: paths.vad, minSilenceDuration: 0.3),
          numThreads: 1,
          debug: false,
        ),
        bufferSizeInSeconds: 30,
      );
    } catch (e) {
      out.send('$e');
      return;
    }

    var stream = recognizer.createStream();
    final meter = NoiseMeter();
    var silenceMs = 0;
    var text = '';

    final inbox = ReceivePort();
    out.send(inbox.sendPort);
    inbox.listen((msg) {
      switch (msg) {
        case _Audio(:final pcm16):
          final sw = Stopwatch()..start();
          final samples = pcm16ToFloat(pcm16);
          vad.acceptWaveform(samples);
          final speaking = vad.isDetected();
          while (!vad.isEmpty()) {
            vad.pop(); // segments are not needed, only the live flag
          }
          meter.add(samples, speech: speaking);
          silenceMs = speaking ? 0 : silenceMs + samples.length * 1000 ~/ 16000;

          stream.acceptWaveform(samples: samples, sampleRate: 16000);
          while (recognizer.isReady(stream)) {
            recognizer.decode(stream);
          }
          text = recognizer.getResult(stream).text;
          out.send(AsrUpdate(
            text: text,
            speaking: speaking,
            silenceMs: silenceMs,
            noisy: meter.isNoisy,
            decodeMs: sw.elapsedMilliseconds,
          ));
        case _Reset():
          stream.free();
          stream = recognizer.createStream();
          vad.reset();
          silenceMs = 0;
          text = '';
        case _Stop():
          stream.free();
          recognizer.free();
          vad.free();
          inbox.close();
      }
    });
  }
}
