import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../quran/riwaya.dart';
import 'audio_catalog.dart';

/// All reciters the app knows: the built-ins, the ones the user added, and
/// the online list from mp3quran.net (cached, so it also shows offline).
class ReciterDirectory extends ChangeNotifier {
  ReciterDirectory(this._prefs, {required this.ayahCount, required this.storageDir});

  static const _key = 'reciters.v1';
  final SharedPreferences _prefs;

  /// Ayahs of a surah in a riwaya (the riwaya's text must be loaded).
  final int Function(Riwaya r, int surah) ayahCount;
  final Future<Directory> Function() storageDir;
  final Map<String, AudioCatalog> _catalogs = {};

  /// Built-ins first, then the reciters the user added.
  List<Reciter> get known => [
        ...Reciter.builtIns,
        for (final j in jsonDecode(_prefs.getString(_key) ?? '[]') as List) Reciter.fromJson(j as Map<String, dynamic>),
      ];

  List<Reciter> knownFor(Riwaya r) => [for (final x in known) if (x.riwaya == r) x];

  Reciter? byId(String id) => known.where((r) => r.id == id).firstOrNull;

  /// Remembers an online reciter, so it stays in the app offline.
  Future<void> add(Reciter r) async {
    if (byId(r.id) != null) return;
    final saved = [for (final x in known) if (!x.builtIn) x.toJson(), r.toJson()];
    await _prefs.setString(_key, jsonEncode(saved));
    notifyListeners();
  }

  /// The catalog of [r], loaded.
  Future<AudioCatalog> catalog(Reciter r) async {
    final c = _catalogs[r.id] ??= AudioCatalog(r, ayahCount: (s) => ayahCount(r.riwaya, s), storageDir: storageDir);
    await c.load();
    return c;
  }

  /// The catalog of [r] if it is already loaded.
  AudioCatalog? loadedCatalog(Reciter r) => _catalogs[r.id]?.isLoaded ?? false ? _catalogs[r.id] : null;

  /// Reciters of riwaya [r] on mp3quran.net, names in [lang] ('ar', 'eng',
  /// 'fr'). Falls back to the last list saved on the phone.
  Future<List<Reciter>> online(Riwaya r, String lang) async {
    final cache = File('${(await storageDir()).path}/reciters_${r.name}_$lang.json');
    try {
      final list = await _fetch(r, lang);
      await cache.writeAsString(jsonEncode([for (final x in list) x.toJson()]));
      return list;
    } catch (_) {
      if (!cache.existsSync()) rethrow;
      return [
        for (final j in jsonDecode(cache.readAsStringSync()) as List) Reciter.fromJson(j as Map<String, dynamic>),
      ];
    }
  }

  static Future<dynamic> _get(HttpClient client, String url) async {
    final res = await (await client.getUrl(Uri.parse(url))).close();
    if (res.statusCode != HttpStatus.ok) throw HttpException('HTTP ${res.statusCode}');
    return jsonDecode(await res.transform(utf8.decoder).join());
  }

  Future<List<Reciter>> _fetch(Riwaya r, String lang) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final reciters = (await _get(client, 'https://www.mp3quran.net/api/v3/reciters?language=$lang&rewaya=${r.mp3quranId}')
          as Map)['reciters'] as List;
      // Which recordings have ayah timings, by folder.
      final reads = <String, int>{
        for (final x in await _get(client, 'https://www.mp3quran.net/api/v3/ayat_timing/reads') as List)
          _folder((x as Map)['folder_url'] as String): x['id'] as int,
      };
      final out = <Reciter>[];
      for (final rec in reciters) {
        for (final m in (rec as Map)['moshaf'] as List) {
          if (((m as Map)['rewaya_id'] as int?) != r.mp3quranId) continue;
          final server = m['server'] as String;
          out.add(Reciter(
            id: 'mp3q_${m['id']}',
            name: '${rec['name']} · ${m['name']}',
            riwaya: r,
            server: server.endsWith('/') ? server : '$server/',
            timingRead: reads[_folder(server)],
            surahs: {for (final s in (m['surah_list'] as String).split(',')) if (s.trim().isNotEmpty) int.parse(s)},
          ));
        }
      }
      // Recordings with ayah timings (the reader follows along) first.
      out.sort((a, b) => (a.timingRead == null ? 1 : 0) - (b.timingRead == null ? 1 : 0));
      return out;
    } finally {
      client.close(force: true);
    }
  }

  static String _folder(String url) => url.replaceAll(RegExp(r'/+$'), '').replaceFirst('http://', 'https://');
}
