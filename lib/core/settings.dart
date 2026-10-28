import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'align/session.dart';
import 'quran/riwaya.dart';

/// User settings, saved on the phone.
class Settings extends ChangeNotifier {
  Settings(this._prefs);
  final SharedPreferences _prefs;

  ThemeMode get themeMode => ThemeMode.values.byName(_prefs.getString('theme') ?? 'system');
  set themeMode(ThemeMode v) => _set('theme', v.name);

  /// null = the phone's language.
  Locale? get locale {
    final c = _prefs.getString('locale');
    return c == null ? null : Locale(c);
  }

  set locale(Locale? v) => v == null ? _remove('locale') : _set('locale', v.languageCode);

  /// Size of the Quran text.
  double get quranFontSize => _prefs.getDouble('quranFont') ?? 28;
  set quranFontSize(double v) => _setDouble('quranFont', v);

  TeacherMode get teacherMode => TeacherMode.values.byName(_prefs.getString('teacherMode') ?? 'strict');
  set teacherMode(TeacherMode v) => _set('teacherMode', v.name);

  /// Ayahs to recite per day.
  int get dailyGoal => _prefs.getInt('dailyGoal') ?? 5;
  set dailyGoal(int v) {
    _prefs.setInt('dailyGoal', v);
    notifyListeners();
  }

  /// The riwaya the user reads and listens to.
  Riwaya get riwaya => Riwaya.values.firstWhere((r) => r.name == _prefs.getString('riwaya'), orElse: () => Riwaya.hafs);
  set riwaya(Riwaya v) => _set('riwaya', v.name);

  /// The chosen reciter id of riwaya [r], or null.
  String? reciterIdFor(Riwaya r) => _prefs.getString('reciter.${r.name}');
  void setReciterFor(Riwaya r, String id) => _set('reciter.${r.name}', id);

  /// The learner's first name, for the greeting (kept on the phone only).
  String get userName => _prefs.getString('userName') ?? '';
  set userName(String v) => _set('userName', v.trim());

  bool get onboarded => _prefs.getBool('onboarded') ?? false;
  set onboarded(bool v) {
    _prefs.setBool('onboarded', v);
    notifyListeners();
  }

  /// Show the Madani page view (true) or the surah as one list (false).
  bool get pageView => _prefs.getBool('pageView') ?? false;
  set pageView(bool v) {
    _prefs.setBool('pageView', v);
    notifyListeners();
  }

  void _set(String k, String v) {
    _prefs.setString(k, v);
    notifyListeners();
  }

  void _setDouble(String k, double v) {
    _prefs.setDouble(k, v);
    notifyListeners();
  }

  void _remove(String k) {
    _prefs.remove(k);
    notifyListeners();
  }
}
