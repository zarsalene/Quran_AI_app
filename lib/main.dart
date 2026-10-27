import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/quran/quran_repo.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(RattilApp(repo: QuranRepo()));
}

class RattilApp extends StatelessWidget {
  const RattilApp({super.key, required this.repo});
  final QuranRepo repo;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6B5A), brightness: b),
          useMaterial3: true,
        );
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(repo: repo),
    );
  }
}
