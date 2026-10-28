import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/audio/audio_catalog.dart';
import 'core/audio/recitation_player.dart';
import 'core/progress/progress_store.dart';
import 'core/quran/quran_repo.dart';
import 'core/settings.dart';

/// The app's long-lived objects.
class AppServices {
  AppServices({required this.repo, required this.audios, required this.player, required this.progress, required this.settings}) {
    settings.addListener(() => player.setCatalog(audio));
  }

  final QuranRepo repo;
  final Map<Reciter, AudioCatalog> audios;
  final RecitationPlayer player;

  /// The reciter chosen for listening.
  AudioCatalog get audio => audios[settings.reciter]!;

  /// The clearest recording of [surah] on the phone, for single words: the
  /// teaching recording first.
  AudioCatalog? wordAudio(int surah) {
    for (final c in [audios[Reciter.husaryMuallim]!, audio]) {
      if (c.isAvailable(surah)) return c;
    }
    return null;
  }
  final ProgressStore progress;
  final Settings settings;

  /// Loads everything the first screen needs.
  static Future<AppServices> create({QuranRepo? repo, Future<Directory> Function()? storageDir}) async {
    final prefs = await SharedPreferences.getInstance();
    final r = repo ?? QuranRepo();
    final audios = {for (final x in Reciter.values) x: AudioCatalog(x, storageDir: storageDir)};
    await Future.wait([r.surahs(), r.meta(), for (final a in audios.values) a.load()]);
    final settings = Settings(prefs);
    return AppServices(
      repo: r,
      audios: audios,
      player: RecitationPlayer(audios[settings.reciter]!),
      progress: ProgressStore(prefs),
      settings: settings,
    );
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
