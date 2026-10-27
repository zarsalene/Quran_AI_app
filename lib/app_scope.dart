import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/audio/audio_catalog.dart';
import 'core/audio/recitation_player.dart';
import 'core/progress/progress_store.dart';
import 'core/quran/quran_repo.dart';
import 'core/settings.dart';

/// The app's long-lived objects.
class AppServices {
  AppServices({required this.repo, required this.audio, required this.player, required this.progress, required this.settings});

  final QuranRepo repo;
  final AudioCatalog audio;
  final RecitationPlayer player;
  final ProgressStore progress;
  final Settings settings;

  /// Loads everything the first screen needs.
  static Future<AppServices> create({QuranRepo? repo, AudioCatalog? audio, RecitationPlayer? player}) async {
    final prefs = await SharedPreferences.getInstance();
    final r = repo ?? QuranRepo();
    final a = audio ?? AudioCatalog();
    await Future.wait([r.surahs(), r.meta(), a.load()]);
    return AppServices(
      repo: r,
      audio: a,
      player: player ?? RecitationPlayer(a),
      progress: ProgressStore(prefs),
      settings: Settings(prefs),
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
