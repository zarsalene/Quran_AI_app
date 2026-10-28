import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../quran/riwaya.dart';

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

/// A reciter's recording in one riwaya.
///
/// Built-in reciters (Hafs) have word timings in the APK. Reciters from
/// mp3quran.net are added by the user: their surahs download with ayah
/// timings when the site has them.
class Reciter {
  const Reciter({
    required this.id,
    required this.name,
    required this.riwaya,
    this.timingsAsset,
    this.server,
    this.timingRead,
    this.bundled = false,
    this.surahs,
  });

  /// Storage key: 'husary_muallim', 'alafasy', or 'mp3q_<moshaf id>'.
  final String id;

  /// Display name (empty for built-ins: the UI names them).
  final String name;
  final Riwaya riwaya;

  /// assets/quran/audio_<id>.json: surah URLs, sizes, word timings.
  final String? timingsAsset;

  /// mp3quran.net folder, ending with '/'. Surah n is 'nnn.mp3' in it.
  final String? server;

  /// mp3quran.net ayat_timing read id, when the site has timings.
  final int? timingRead;

  /// Al-Fatiha and Juz 30 are in the APK (tool/fetch_audio.py).
  final bool bundled;

  /// Surahs the recording has (null: all 114).
  final Set<int>? surahs;

  bool get builtIn => timingsAsset != null;
  bool has(int surah) => surahs?.contains(surah) ?? true;

  /// Al-Husary, the teaching recording: slow and exact, with a pause after
  /// each ayah to repeat. Al-Fatiha and Juz 30 ship in the APK.
  static const husaryMuallim = Reciter(
    id: 'husary_muallim',
    name: '',
    riwaya: Riwaya.hafs,
    timingsAsset: 'assets/quran/audio_husary_muallim.json',
    bundled: true,
  );

  /// Mishary Alafasy, murattal, with word timings. Downloads per surah.
  static const alafasy =
      Reciter(id: 'alafasy', name: '', riwaya: Riwaya.hafs, timingsAsset: 'assets/quran/audio_alafasy.json');

  static const builtIns = [husaryMuallim, alafasy];

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'riwaya': riwaya.name,
        'server': server,
        'read': timingRead,
        'surahs': surahs?.toList(),
      };

  factory Reciter.fromJson(Map<String, dynamic> j) => Reciter(
        id: j['id'] as String,
        name: j['name'] as String,
        riwaya: Riwaya.values.byName(j['riwaya'] as String),
        server: j['server'] as String?,
        timingRead: j['read'] as int?,
        surahs: (j['surahs'] as List?)?.map((e) => e as int).toSet(),
      );
}

/// One reciter's recording: bundled surahs, downloads, and timings.
class AudioCatalog extends ChangeNotifier {
  AudioCatalog(
    this.reciter, {
    required this.ayahCount,
    AssetBundle? bundle,
    Future<Directory> Function()? storageDir,
  })  : _bundle = bundle ?? rootBundle,
        _storageDir = storageDir ?? getApplicationSupportDirectory;

  /// Surahs shipped in the APK for a bundled reciter: Al-Fatiha and Juz 30.
  static final bundledSurahs = {1, for (var s = 78; s <= 114; s++) s};

  final Reciter reciter;

  /// Ayahs of each surah in this reciter's riwaya, to check timings.
  final int Function(int surah) ayahCount;

  final AssetBundle _bundle;
  final Future<Directory> Function() _storageDir;
  Map<int, SurahAudio>? _builtIn;
  final Map<int, SurahAudio> _downloadedTimings = {};
  Directory? _dir;
  bool _loaded = false;
  final Set<int> _downloaded = {};

  /// Download progress (0..1) of surahs being downloaded.
  final Map<int, double> downloading = {};
  final Map<int, Object> downloadErrors = {};

  Future<void> load() async {
    if (_loaded) return;
    final asset = reciter.timingsAsset;
    if (asset != null) {
      _builtIn = _parse(jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>);
    }
    final dir = Directory('${(await _storageDir()).path}/audio/${reciter.id}');
    await dir.create(recursive: true);
    _dir = dir;
    for (final f in dir.listSync().whereType<File>()) {
      final m = RegExp(r's(\d{3})\.mp3$').firstMatch(f.path);
      if (m == null) continue;
      final s = int.parse(m.group(1)!);
      _downloaded.add(s);
      final t = File('${dir.path}/s${m.group(1)}.json');
      if (asset == null && t.existsSync()) {
        try {
          _downloadedTimings[s] = _surahFromAyahs(s, '', 0, jsonDecode(t.readAsStringSync()) as List);
        } catch (_) {
          // A broken timing file: the surah still plays as a whole.
        }
      }
    }
    _loaded = true;
    notifyListeners();
  }

  static Map<int, SurahAudio> _parse(Map<String, dynamic> j) => {
        for (final s in j['surahs'] as List)
          (s as Map<String, dynamic>)['s'] as int:
              _surahFromAyahs(s['s'] as int, s['url'] as String, s['bytes'] as int, s['ayahs'] as List),
      };

  static SurahAudio _surahFromAyahs(int s, String url, int bytes, List ayahs) => SurahAudio(
        surah: s,
        url: url,
        bytes: bytes,
        ayahs: [
          for (final a in ayahs)
            AyahTiming((a as List)[0] as int, a[1] as int, [
              for (final w in a[2] as List) (word: (w as List)[0] as int, from: w[1] as int, to: w[2] as int),
            ]),
        ],
      );

  bool get isLoaded => _loaded;

  /// Ayah timings of surah [n], or null when the recording has none (the
  /// surah then plays as a whole).
  SurahAudio? surah(int n) => _builtIn?[n] ?? _downloadedTimings[n];

  /// Word timings exist (built-in reciters only).
  bool get hasWordTimings => reciter.builtIn;

  String _url(int s) => _builtIn?[s]?.url ?? '${reciter.server}${s.toString().padLeft(3, '0')}.mp3';

  File _file(int s) => File('${_dir!.path}/s${s.toString().padLeft(3, '0')}.mp3');

  AudioLocation location(int s) {
    if (reciter.bundled && bundledSurahs.contains(s)) {
      return BundledAudio('assets/audio/${reciter.id}/s${s.toString().padLeft(3, '0')}.mp3');
    }
    if (_downloaded.contains(s)) return DownloadedAudio(_file(s).path);
    return const MissingAudio();
  }

  bool isAvailable(int s) => location(s) is! MissingAudio;

  /// Surahs on the phone (bundled or downloaded).
  int get availableCount => [for (var s = 1; s <= 114; s++) if (isAvailable(s)) s].length;

  /// Surahs this recording has that are not on the phone yet.
  List<int> get missing => [for (var s = 1; s <= 114; s++) if (reciter.has(s) && !isAvailable(s)) s];

  /// Bytes still to download, when the sizes are known (built-ins).
  int? missingBytes() {
    final b = _builtIn;
    if (b == null) return null;
    return [for (final s in missing) b[s]!.bytes].fold<int>(0, (a, x) => a + x);
  }

  int downloadedBytes() => [
        for (final s in _downloaded)
          if (_file(s).existsSync()) _file(s).lengthSync(),
      ].fold(0, (a, b) => a + b);

  /// Downloads one surah (and its ayah timings for mp3quran reciters).
  /// Resumes a partial download. Safe to call twice.
  Future<void> download(int s) async {
    if (isAvailable(s) || downloading.containsKey(s) || !reciter.has(s)) return;
    downloading[s] = 0;
    downloadErrors.remove(s);
    notifyListeners();
    final part = File('${_file(s).path}.part');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      var have = await part.exists() ? await part.length() : 0;
      final req = await client.getUrl(Uri.parse(_url(s)));
      if (have > 0) req.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
      final res = await req.close();
      if (res.statusCode == HttpStatus.ok) {
        have = 0; // the server sent the whole file
      } else if (res.statusCode != HttpStatus.partialContent) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      final total = _builtIn?[s]?.bytes ?? (res.contentLength > 0 ? have + res.contentLength : -1);
      final sink = part.openWrite(mode: have == 0 ? FileMode.write : FileMode.append);
      var got = have;
      var lastNotify = DateTime.now();
      try {
        await for (final chunk in res) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0 && DateTime.now().difference(lastNotify).inMilliseconds > 250) {
            lastNotify = DateTime.now();
            downloading[s] = (got / total).clamp(0, 1);
            notifyListeners();
          }
        }
      } finally {
        await sink.close();
      }
      if (total > 0 && await part.length() != total) {
        await part.delete();
        throw const HttpException('incomplete download');
      }
      if (!reciter.builtIn && reciter.timingRead != null) await _fetchTimings(client, s);
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

  /// Ayah timings from mp3quran.net. Kept only when there is exactly one
  /// timing per ayah of the riwaya, in order and forward in time; otherwise
  /// the surah plays as a whole (never with a wrong ayah highlighted).
  Future<void> _fetchTimings(HttpClient client, int s) async {
    try {
      final uri = Uri.parse('https://www.mp3quran.net/api/v3/ayat_timing?surah=$s&read=${reciter.timingRead}');
      final res = await (await client.getUrl(uri)).close();
      if (res.statusCode != HttpStatus.ok) return;
      final rows = [
        for (final r in jsonDecode(await res.transform(utf8.decoder).join()) as List)
          if (((r as Map)['ayah'] as int) > 0) r,
      ];
      final ayahs = [for (final r in rows) [r['start_time'] as int, r['end_time'] as int, const <Object>[]]];
      if (!validAyahTimings([for (final r in rows) (r['ayah'] as int, r['start_time'] as int)], ayahCount(s))) return;
      await File('${_dir!.path}/s${s.toString().padLeft(3, '0')}.json').writeAsString(jsonEncode(ayahs));
      _downloadedTimings[s] = _surahFromAyahs(s, '', 0, ayahs);
    } catch (_) {
      // Timings are a help: the surah still plays as a whole.
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
    for (final s in missing) {
      if (_cancelAll) break;
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
      for (final ext in ['mp3', 'json']) {
        final f = File('${_dir!.path}/s${s.toString().padLeft(3, '0')}.$ext');
        if (await f.exists()) await f.delete();
      }
    }
    _downloaded.clear();
    _downloadedTimings.clear();
    notifyListeners();
  }
}

/// Ayah timings fit a surah of [ayahs] ayahs: one per ayah, numbered 1..n in
/// order, with start times that never go back.
bool validAyahTimings(List<(int ayah, int start)> rows, int ayahs) {
  if (rows.length != ayahs) return false;
  for (var i = 0; i < rows.length; i++) {
    if (rows[i].$1 != i + 1) return false;
    if (i > 0 && rows[i].$2 < rows[i - 1].$2) return false;
  }
  return true;
}
