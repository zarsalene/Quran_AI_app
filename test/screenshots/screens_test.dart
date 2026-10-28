// Renders the main screens at phone size with the real fonts, for design
// review. Skipped unless SCREENSHOTS=1:
//
//   SCREENSHOTS=1 flutter test test/screenshots --update-goldens
//
// PNGs land in test/screenshots/out/ (not in Git).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app_scope.dart';
import 'package:rattil/features/hifz/memorize_screen.dart';
import 'package:rattil/features/reader/mushaf_screen.dart';
import 'package:rattil/features/reader/reader_screen.dart';
import 'package:rattil/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _enabled = Platform.environment['SCREENSHOTS'] == '1';

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final bytes = File(f).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  final flutterRoot = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final icons = ['$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf'];
  await family('MaterialIcons', icons);
  await family('AmiriQuran', ['assets/fonts/AmiriQuran-Regular.ttf']);
  await family('Amiri', ['assets/fonts/Amiri-Bold.ttf']);
  await family('PlexArabic', [
    'assets/fonts/IBMPlexSansArabic-Regular.ttf',
    'assets/fonts/IBMPlexSansArabic-Medium.ttf',
    'assets/fonts/IBMPlexSansArabic-SemiBold.ttf',
    'assets/fonts/IBMPlexSansArabic-Bold.ttf',
  ]);
}

void main() {
  setUpAll(() async {
    if (_enabled) await _loadFonts();
  });

  Future<AppServices> start(WidgetTester tester, Locale locale, {bool onboarded = true, bool dark = false}) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'onboarded': onboarded,
      if (dark) 'theme': 'dark',
      'progress.v1': '{"rec":{},"days":[],"cards":{"1:1":{"r":2,"e":2.5,"i":3,"d":"2099-01-01"}},"bm":[],"badges":["streak7"],"best":9}',
    });
    final services = (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('rattil_shots');
      final s = await AppServices.create(storageDir: () async => dir);
      for (final n in [1, 112, 114, 2]) {
        await s.repo.surah(n);
      }
      return s;
    }))!;
    await tester.pumpWidget(RattilApp(services: services));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    return services;
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$name.png'));
  }

  Future<void> push(WidgetTester tester, Widget page) async {
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => page));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pumpAndSettle();
  }

  for (final (code, label) in [('fr', 'fr'), ('ar', 'ar')]) {
    testWidgets('screens $label', (tester) async {
      await start(tester, Locale(code), onboarded: false);
      await shot(tester, '${label}_01_onboarding');
      await start(tester, Locale(code));
      await shot(tester, '${label}_02_today');
      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();
      await shot(tester, '${label}_03_quran');
      await tester.tap(find.text(code == 'ar' ? 'الفاتحة' : 'Al-Faatiha').first);
      await tester.pumpAndSettle();
      await shot(tester, '${label}_04_actions');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await push(tester, const ReaderScreen(surah: 112));
      await shot(tester, '${label}_05_reader');
      await push(tester, const MushafScreen(initialPage: 604));
      await shot(tester, '${label}_06_mushaf');
      await push(tester, const MemorizeScreen(surah: 114, from: 1, to: 3));
      await shot(tester, '${label}_07_memorize');
    }, skip: !_enabled);
  }

  testWidgets('screens dark', (tester) async {
    await start(tester, const Locale('fr'), dark: true);
    await shot(tester, 'dark_02_today');
    await tester.tap(find.byIcon(Icons.insights_outlined));
    await tester.pumpAndSettle();
    await shot(tester, 'dark_08_progress');
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await shot(tester, 'dark_09_settings');
  }, skip: !_enabled);
}
