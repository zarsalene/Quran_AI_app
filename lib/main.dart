import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell.dart';
import 'l10n/app_localizations.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RattilApp(services: await AppServices.create()));
}

class RattilApp extends StatelessWidget {
  const RattilApp({super.key, required this.services});
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final settings = services.settings;
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: rattilTheme(Brightness.light),
          darkTheme: rattilTheme(Brightness.dark),
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
