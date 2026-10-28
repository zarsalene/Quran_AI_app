import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// One word segment: word index in the ayah (0-based) and its time in ms.
typedef WordSeg = ({int word, int from, int to});

class AyahTiming {
  const AyahTiming(this.from, this.to, this.segs);

  /// Start and end of the ayah in the surah file, in ms.
  final int from;
  final int to;

  /// Word segments in time order. A word can appear twice when the reciter
  /// repeats a phrase, and a few words have no segment.
  final List<WordSeg> segs;

  /// Start of the ayah, including a first word that starts a little early.
  int get start => segs.isEmpty || segs.first.from > from ? from : segs.first.from;

  /// Word being recited at [ms], or null between words.
  int? wordAt(int ms) {
    for (final s in segs) {
      if (ms >= s.from && ms < s.to) return s.word;
    }
    return null;
  }

  /// Time span that holds [word]. A word with no segment plays from the word
  /// before it to the word after it, so it is always heard.
  (int, int) wordSpan(int word) {
    WordSeg? exact, before, after;
    for (final s in segs) {
      if (s.word == word) exact = s; // the last time, after any repeat
      if (s.word < word && (before == null || s.word >= before.word)) before = s;
      if (s.word > word && after == null) after = s;
    }
    if (exact != null) return (exact.from, exact.to);
    return (before?.from ?? start, after?.to ?? to);
  }
}

class SurahAudio {
  const SurahAudio({required this.surah, required this.url, required this.bytes, required this.ayahs});
  final int surah;
  final String url;
  final int bytes;
  final List<AyahTiming> ayahs;

  AyahTiming ayah(int number) => ayahs[number - 1];
}

/// Where the audio of a surah is.
sealed class AudioLocation {
  const AudioLocation();
}

class BundledAudio extends AudioLocation {
  const BundledAudio(this.asset);
  final String asset;
}

class DownloadedAudio extends AudioLocation {
  const DownloadedAudio(this.path);
  final String path;
}

class MissingAudio extends AudioLocation {
  const MissingAudio();
}

/// A recitation the app can play. Each has word timings from quran.com.
enum Reciter {
  /// Al-Husary, the teaching recording: slow and exact, with a pause after
  /// each ayah to repeat. Al-Fatiha and Juz 30 ship in the APK.
  husaryMuallim('husary_muallim', bundled: true),

  /// Mishary Alafasy, murattal. Downloads per surah.
  alafasy('alafasy');

  const Reciter(this.key, {this.bundled = false});
  final String key;

  /// Al-Fatiha and Juz 30 are in the APK (tool/fetch_audio.py).
  final bool bundled;
}

/// One reciter's recitation: bundled surahs, downloads, and word timings.
class AudioCatalog extends ChangeNotifier {
  AudioCatalog(this.reciter, {AssetBundle? bundle, Future<Directory> Function()? storageDir})
      : _bundle = bundle ?? rootBundle,
        _storageDir = storageDir ?? getApplicationSupportDirectory;

  /// Surahs shipped in the APK for a bundled reciter: Al-Fatiha and Juz 30.
  static final bundledSurahs = {1, for (var s = 78; s <= 114; s++) s};

  final Reciter reciter;

  final AssetBundle _bundle;
  final Future<Directory> Function() _storageDir;
  Map<int, SurahAudio>? _surahs;
  Directory? _dir;
  final Set<int> _downloaded = {};

  /// Download progress (0..1) of surahs being downloaded.
  final Map<int, double> downloading = {};
  final Map<int, Object> downloadErrors = {};

  Future<void> load() async {
    if (_surahs != null) return;
    final j = jsonDecode(await _bundle.loadString('assets/quran/audio_${reciter.key}.json')) as Map<String, dynamic>;
    _surahs = {
      for (final s in j['surahs'] as List)
        (s as Map<String, dynamic>)['s'] as int: SurahAudio(
          surah: s['s'] as int,
          url: s['url'] as String,
          bytes: s['bytes'] as int,
          ayahs: [
            for (final a in s['ayahs'] as List)
              AyahTiming((a as List)[0] as int, a[1] as int, [
                for (final w in a[2] as List) (word: (w as List)[0] as int, from: w[1] as int, to: w[2] as int),
              ]),
          ],
        ),
    };
    final dir = Directory('${(await _storageDir()).path}/audio/${reciter.key}');
    await dir.create(recursive: true);
    _dir = dir;
    for (final f in dir.listSync().whereType<File>()) {
      final m = RegExp(r's(\d{3})\.mp3$').firstMatch(f.path);
      if (m != null) _downloaded.add(int.parse(m.group(1)!));
    }
    notifyListeners();
  }

  bool get isLoaded => _surahs != null;
  SurahAudio surah(int number) => _surahs![number]!;

  File _file(int s) => File('${_dir!.path}/s${s.toString().padLeft(3, '0')}.mp3');

  AudioLocation location(int s) {
    if (reciter.bundled && bundledSurahs.contains(s)) {
      return BundledAudio('assets/audio/${reciter.key}/s${s.toString().padLeft(3, '0')}.mp3');
    }
    if (_downloaded.contains(s)) return DownloadedAudio(_file(s).path);
    return const MissingAudio();
  }

  bool isAvailable(int s) => location(s) is! MissingAudio;

  /// Bytes of the surahs still to download.
  int missingBytes() => [
        for (var s = 1; s <= 114; s++)
          if (!isAvailable(s)) _surahs![s]!.bytes,
      ].fold(0, (a, b) => a + b);

  int downloadedBytes() => [for (final s in _downloaded) _surahs![s]!.bytes].fold(0, (a, b) => a + b);

  /// Downloads one surah. Resumes a partial download. Safe to call twice.
  Future<void> download(int s) async {
    if (isAvailable(s) || downloading.containsKey(s)) return;
    final info = _surahs![s]!;
    downloading[s] = 0;
    downloadErrors.remove(s);
    notifyListeners();
    final part = File('${_file(s).path}.part');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      var have = await part.exists() ? await part.length() : 0;
      final req = await client.getUrl(Uri.parse(info.url));
      if (have > 0) req.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
      final res = await req.close();
      if (res.statusCode == HttpStatus.ok) {
        have = 0; // the server sent the whole file
      } else if (res.statusCode != HttpStatus.partialContent) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      final sink = part.openWrite(mode: have == 0 ? FileMode.write : FileMode.append);
      var got = have;
      var lastNotify = DateTime.now();
      try {
        await for (final chunk in res) {
          sink.add(chunk);
          got += chunk.length;
          if (DateTime.now().difference(lastNotify).inMilliseconds > 250) {
            lastNotify = DateTime.now();
            downloading[s] = (got / info.bytes).clamp(0, 1);
            notifyListeners();
          }
        }
      } finally {
        await sink.close();
      }
      if (await part.length() != info.bytes) {
        await part.delete();
        throw const HttpException('incomplete download');
      }
      await part.rename(_file(s).path);
      _downloaded.add(s);
    } catch (e) {
      downloadErrors[s] = e;
    } finally {
      client.close(force: true);
      downloading.remove(s);
      notifyListeners();
    }
  }

  bool _cancelAll = false;
  bool get downloadingAll => _downloadingAll;
  bool _downloadingAll = false;

  /// Downloads every surah that is not on the phone yet, one at a time.
  Future<void> downloadAll() async {
    if (_downloadingAll) return;
    _downloadingAll = true;
    _cancelAll = false;
    notifyListeners();
    for (var s = 1; s <= 114 && !_cancelAll; s++) {
      await download(s);
    }
    _downloadingAll = false;
    notifyListeners();
  }

  /// Stops "download all" after the current surah.
  void cancelAll() {
    _cancelAll = true;
    notifyListeners();
  }

  /// Deletes all downloaded audio. Bundled surahs stay.
  Future<void> deleteDownloads() async {
    for (final s in _downloaded.toList()) {
      final f = _file(s);
      if (await f.exists()) await f.delete();
    }
    _downloaded.clear();
    notifyListeners();
  }
}
