import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RattilApp(services: await AppServices.create()));
}

const brandGreen = Color(0xFF1B6B5A);

class RattilApp extends StatelessWidget {
  const RattilApp({super.key, required this.services});
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: brandGreen, brightness: b),
          useMaterial3: true,
          visualDensity: VisualDensity.standard,
        );
    final settings = services.settings;
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: theme(Brightness.light),
          darkTheme: theme(Brightness.dark),
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: settings.onboarded ? const Shell() : const OnboardingScreen(),
        ),
      ),
    );
  }
}
