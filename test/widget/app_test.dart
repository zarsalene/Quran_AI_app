import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/core/quran/quran_repo.dart';
import 'package:rattil/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Locale locale) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    // Asset loading is real I/O: do it outside the fake clock first, so the
    // home screen finds the surah list cached.
    final repo = QuranRepo();
    await tester.runAsync(repo.surahs);
    await tester.pumpWidget(RattilApp(repo: repo));
    await tester.pumpAndSettle();
  }

  testWidgets('home opens with Al-Fatiha first (English)', (tester) async {
    await pumpApp(tester, const Locale('en'));
    expect(find.text('Start with a short surah'), findsOneWidget);
    expect(find.text('Al-Faatiha · 7 ayahs'), findsOneWidget);
  });

  testWidgets('home is in Arabic and right-to-left for an Arabic phone', (tester) async {
    await pumpApp(tester, const Locale('ar'));
    expect(find.text('ابدأ بسورة قصيرة'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.byType(ListView)));
    expect(dir, TextDirection.rtl);
  });
}
