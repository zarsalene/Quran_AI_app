// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Rattil';

  @override
  String get homeStart => 'Commencez par une sourate courte';

  @override
  String get homeAll => 'Toutes les sourates';

  @override
  String ayahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versets',
      one: '1 verset',
    );
    return '$_temp0';
  }

  @override
  String get modeStrict => 'Strict';

  @override
  String get modeGentle => 'Doux';

  @override
  String get modeStrictHelp => 'S\'arrête à une erreur';

  @override
  String get modeGentleHelp => 'Marque les erreurs et continue';

  @override
  String get teacherLoading => 'Préparation de l\'enseignant…';

  @override
  String get tapToStart => 'Touchez le micro et récitez';

  @override
  String get listening => 'À l\'écoute…';

  @override
  String get stopTitle => 'Vérifiez ce mot';

  @override
  String get stopBody => 'Récitez de nouveau à partir de ce mot.';

  @override
  String get repeatFromHere => 'Réciter à partir d\'ici';

  @override
  String get jumpedBody =>
      'Vous êtes passé à un autre endroit. Revenez au premier mot oublié.';

  @override
  String get unsure => 'Pas sûr. Écoutez le récitateur.';

  @override
  String get tooNoisy => 'Trop de bruit. Allez dans un endroit plus calme.';

  @override
  String get perfect => 'Parfait';

  @override
  String doneWithMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Terminé. $count erreurs à revoir.',
      one: 'Terminé. 1 erreur à revoir.',
    );
    return '$_temp0';
  }

  @override
  String get doneNotPerfect => 'Terminé. Vérifiez les mots en orange.';

  @override
  String get again => 'Recommencer';

  @override
  String get disclaimer =>
      'La correction automatique peut se tromper. Elle ne remplace pas un enseignant qualifié.';

  @override
  String get micTitle => 'Microphone';

  @override
  String get micBody =>
      'Rattil écoute votre récitation pour la vérifier. Le son reste sur votre téléphone. Il n\'est jamais envoyé.';

  @override
  String get micContinue => 'Continuer';

  @override
  String get micDenied =>
      'Rattil a besoin du micro pour écouter votre récitation. Autorisez-le dans les réglages du téléphone.';

  @override
  String errorStart(String message) {
    return 'L\'enseignant n\'a pas pu démarrer : $message';
  }

  @override
  String get issueMissingWord => 'Mot manquant';

  @override
  String get issueWrongLetter => 'Lettre fausse';

  @override
  String get issueMissingLetter => 'Lettre manquante';

  @override
  String get issueExtraLetter => 'Lettre en trop';

  @override
  String get issueExtraWord => 'Mot en trop';

  @override
  String get issueHarakat => 'Voyelle (haraka)';

  @override
  String get issueLongVowel => 'Voyelle longue';

  @override
  String get issueShadda => 'Chadda';

  @override
  String get issueTajweed => 'Conseil de tajwid (bêta)';

  @override
  String get legendCorrect => 'Correct';

  @override
  String get legendCheck => 'À vérifier';

  @override
  String get legendMistake => 'Erreur';
}
