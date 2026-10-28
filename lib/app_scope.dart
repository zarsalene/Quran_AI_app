import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/audio/audio_catalog.dart';
import 'core/audio/recitation_player.dart';
import 'core/audio/reciters.dart';
import 'core/progress/progress_store.dart';
import 'core/quran/quran_repo.dart';
import 'core/quran/riwaya.dart';
import 'core/settings.dart';

/// The app's long-lived objects.
class AppServices {
  AppServices({
    required this.repo,
    required this.reciters,
    required this.player,
    required this.progress,
    required this.settings,
    required Map<String, AudioCatalog> catalogs,
  }) : _catalogs = catalogs {
    settings.addListener(_syncPlayer);
    reciters.addListener(_syncPlayer);
  }

  final QuranRepo repo;
  final ReciterDirectory reciters;
  final RecitationPlayer player;
  final ProgressStore progress;
  final Settings settings;

  /// Loaded catalogs by reciter id.
  final Map<String, AudioCatalog> _catalogs;

  Riwaya get riwaya => settings.riwaya;

  /// Surahs with the ayah counts of the current riwaya.
  List<SurahInfo> get surahs => repo.infosFor(riwaya);

  /// Pages and juz of the current riwaya's mushaf.
  QuranMeta get meta => repo.metaFor(riwaya);

  /// Surah [n] in the current riwaya.
  Future<QSurah> text(int n) => repo.surahFor(riwaya, n);

  /// The chosen reciter of the current riwaya, or null if none is chosen.
  Reciter? get reciter {
    final id = settings.reciterIdFor(riwaya) ?? (riwaya == Riwaya.hafs ? Reciter.husaryMuallim.id : null);
    final r = id == null ? null : reciters.byId(id);
    return r != null && r.riwaya == riwaya ? r : null;
  }

  /// The chosen reciter's recording, once loaded.
  AudioCatalog? get audio {
    final r = reciter;
    return r == null ? null : _catalogs[r.id] ?? reciters.loadedCatalog(r);
  }

  /// The clearest recording of [surah] for single words: Hafs only (word
  /// timings), the teaching recording first.
  AudioCatalog? wordAudio(int surah) {
    if (riwaya != Riwaya.hafs) return null;
    for (final c in [_catalogs[Reciter.husaryMuallim.id], audio]) {
      if (c != null && c.hasWordTimings && c.isAvailable(surah)) return c;
    }
    return null;
  }

  /// Switches the riwaya after its text is loaded, and loads its reciter.
  Future<void> setRiwaya(Riwaya r) async {
    await repo.loadRiwaya(r);
    await player.stop();
    settings.riwaya = r;
    final rec = reciter;
    if (rec != null && audio == null) {
      _catalogs[rec.id] = await reciters.catalog(rec);
      _syncPlayer();
    }
  }

  /// Makes [r] the reciter of its riwaya (loads its catalog first).
  Future<void> useReciter(Reciter r) async {
    if (!r.builtIn) await reciters.add(r);
    _catalogs[r.id] = await reciters.catalog(r);
    settings.setReciterFor(r.riwaya, r.id);
  }

  void _syncPlayer() {
    final a = audio;
    if (a != null) player.setCatalog(a);
  }

  /// Loads everything the first screen needs.
  static Future<AppServices> create({QuranRepo? repo, Future<Directory> Function()? storageDir}) async {
    final prefs = await SharedPreferences.getInstance();
    final r = repo ?? QuranRepo();
    final settings = Settings(prefs);
    final dir = storageDir ?? getApplicationSupportDirectory;
    await Future.wait([r.surahs(), r.meta(), r.loadRiwaya(settings.riwaya)]);
    final directory = ReciterDirectory(prefs, ayahCount: (rw, s) => r.infosFor(rw)[s - 1].ayahs, storageDir: dir);
    final catalogs = <String, AudioCatalog>{};
    final wanted = {
      Reciter.husaryMuallim,
      for (final rw in Riwaya.values)
        if (settings.reciterIdFor(rw) case final id?) ?directory.byId(id),
    };
    for (final rec in wanted) {
      if (r.isLoaded(rec.riwaya)) catalogs[rec.id] = await directory.catalog(rec);
    }
    final services = AppServices(
      repo: r,
      reciters: directory,
      player: RecitationPlayer(catalogs[Reciter.husaryMuallim.id]!),
      progress: ProgressStore(prefs),
      settings: settings,
      catalogs: catalogs,
    );
    services._syncPlayer();
    return services;
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final AppServices services;

  static AppServices of(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
