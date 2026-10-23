import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/core/asr/pcm.dart';

Float32List tone(double amplitude, {int n = 1600}) =>
    Float32List.fromList([for (var i = 0; i < n; i++) amplitude * math.sin(i * 0.3)]);

void main() {
  test('pcm16ToFloat reads little-endian samples and ignores an odd byte', () {
    final bytes = Uint8List.fromList([0x00, 0x40, 0x00, 0xC0, 0xFF, 0x7F, 0x12]);
    final f = pcm16ToFloat(bytes);
    expect(f, hasLength(3));
    expect(f[0], closeTo(0.5, 1e-6));
    expect(f[1], closeTo(-0.5, 1e-6));
    expect(f[2], closeTo(32767 / 32768, 1e-6));
  });

  test('rmsDbfs', () {
    expect(rmsDbfs(Float32List(10)), -120);
    expect(rmsDbfs(Float32List.fromList([1, -1, 1, -1])), closeTo(0, 1e-9));
    expect(rmsDbfs(Float32List.fromList([0.1, -0.1])), closeTo(-20, 1e-5));
  });

  group('NoiseMeter', () {
    test('a quiet room with clear speech is not noisy', () {
      final m = NoiseMeter();
      for (var i = 0; i < 20; i++) {
        m.add(tone(0.001), speech: false); // about -63 dBFS
        m.add(tone(0.2), speech: true); // about -17 dBFS
      }
      expect(m.isNoisy, isFalse);
    });

    test('a loud background is noisy', () {
      final m = NoiseMeter();
      for (var i = 0; i < 20; i++) {
        m.add(tone(0.05), speech: false); // about -29 dBFS
      }
      expect(m.isNoisy, isTrue);
    });

    test('speech too close to the background is noisy', () {
      final m = NoiseMeter();
      for (var i = 0; i < 20; i++) {
        m.add(tone(0.008), speech: false); // about -45 dBFS
        m.add(tone(0.016), speech: true); // only 6 dB louder
      }
      expect(m.isNoisy, isTrue);
    });

    test('no silence heard yet means no verdict', () {
      final m = NoiseMeter()..add(tone(0.2), speech: true);
      expect(m.isNoisy, isFalse);
    });
  });
}
