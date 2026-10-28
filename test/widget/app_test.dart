import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app_scope.dart';
import 'package:rattil/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Locale locale, {bool onboarded = true}) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    // A common phone: 393 x 851 logical pixels. Layout overflows fail the test.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'onboarded': onboarded});
    // Asset loading is real I/O: do it outside the fake clock.
    final services = (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('rattil_test');
      return AppServices.create(storageDir: () async => dir);
    }))!;
    await tester.pumpWidget(RattilApp(services: services));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch: three onboarding screens, then Today', (tester) async {
    await pumpApp(tester, const Locale('en'), onboarded: false);
    expect(find.text('Learn the Quran with a teacher on your phone'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('The teacher listens to you'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 ayahs'));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Start with Al-Fatiha'), findsOneWidget);
    expect(find.text('0 of 10 ayahs recited'), findsOneWidget);
  });

  testWidgets('Today lists short surahs, Al-Fatiha first (English)', (tester) async {
    await pumpApp(tester, const Locale('en'));
    expect(find.text('Ayah of the day'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Start with a short surah'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Al-Faatiha'), findsWidgets);
  });

  testWidgets('Arabic phone: Arabic and right-to-left', (tester) async {
    await pumpApp(tester, const Locale('ar'));
    await tester.scrollUntilVisible(find.text('ابدأ بسورة قصيرة'), 300, scrollable: find.byType(Scrollable).first);
    final dir = Directionality.of(tester.element(find.byType(ListView).first));
    expect(dir, TextDirection.rtl);
  });

  testWidgets('a surah opens Recite, Memorize, and Read in 1 tap', (tester) async {
    await pumpApp(tester, const Locale('en'));
    await tester.tap(find.text('Quran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Al-Baqara'));
    await tester.pumpAndSettle();
    expect(find.text('Recite'), findsWidgets);
    expect(find.text('Memorize'), findsWidgets);
    expect(find.text('Read & listen'), findsWidgets);
    expect(find.text('Ayahs 1–286'), findsOneWidget);
  });
}
