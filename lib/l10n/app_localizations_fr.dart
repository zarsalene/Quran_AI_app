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

  @override
  String get navToday => 'Aujourd\'hui';

  @override
  String get navQuran => 'Coran';

  @override
  String get navProgress => 'Progrès';

  @override
  String get navSettings => 'Réglages';

  @override
  String get actionRead => 'Lire et écouter';

  @override
  String get actionRecite => 'Réciter';

  @override
  String get actionMemorize => 'Mémoriser';

  @override
  String get readHelp => 'Suivez le récitant mot par mot';

  @override
  String get reciteHelp => 'Le professeur vérifie chaque mot';

  @override
  String get memorizeHelp => 'Verset par verset, avec révisions';

  @override
  String get meccan => 'Mecquoise';

  @override
  String get medinan => 'Médinoise';

  @override
  String ayahN(int n) {
    return 'Verset $n';
  }

  @override
  String ayahRange(int from, int to) {
    return 'Versets $from–$to';
  }

  @override
  String pageN(int n) {
    return 'Page $n';
  }

  @override
  String juzN(int n) {
    return 'Juz $n';
  }

  @override
  String get goalTitle => 'Objectif du jour';

  @override
  String goalProgress(int done, int goal) {
    return '$done sur $goal versets récités';
  }

  @override
  String get goalDone => 'Objectif atteint. Bravo !';

  @override
  String goalAyahs(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n versets',
      one: '1 verset',
    );
    return '$_temp0';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours de suite',
      one: '1 jour de suite',
      zero: 'Commencez votre série aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get continueTitle => 'Continuer';

  @override
  String get startTitle => 'Commencez par Al-Fatiha';

  @override
  String get reviewTitle => 'Révision';

  @override
  String reviewDue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n versets à réviser',
      one: '1 verset à réviser',
    );
    return '$_temp0';
  }

  @override
  String get reviewEmpty => 'Rien à réviser aujourd\'hui.';

  @override
  String reviewDone(int good, int total) {
    return 'Terminé : $good versets sur $total bien retenus.';
  }

  @override
  String get chooseSurah => 'Choisissez une sourate';

  @override
  String get search => 'Rechercher';

  @override
  String get searchHint => 'Mot, sourate ou 2:255';

  @override
  String get searchNoResults => 'Aucun résultat';

  @override
  String get tabSurahs => 'Sourates';

  @override
  String get tabJuz => 'Juz';

  @override
  String get bookmarks => 'Signets';

  @override
  String get noBookmarks =>
      'Pas encore de signet. Touchez un verset pour en ajouter un.';

  @override
  String get pageView => 'Vue page';

  @override
  String get listView => 'Vue liste';

  @override
  String get playFromHere => 'Écouter à partir d\'ici';

  @override
  String get repeatAyah => 'Répéter ce verset';

  @override
  String get reciteFromHere => 'Réciter à partir d\'ici';

  @override
  String get memorizeAyah => 'Mémoriser ce verset';

  @override
  String get bookmarkAdd => 'Ajouter un signet';

  @override
  String get bookmarkRemove => 'Retirer le signet';

  @override
  String get play => 'Lecture';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Arrêter';

  @override
  String get loop => 'Répéter la plage';

  @override
  String get speed => 'Vitesse';

  @override
  String get repeatEachTooltip => 'Nombre d\'écoutes par verset';

  @override
  String get reciterName => 'Mishary Rashid Alafasy';

  @override
  String get audioMissing =>
      'L\'audio de cette sourate n\'est pas sur votre téléphone.';

  @override
  String downloadSize(String mb) {
    return 'Télécharger ($mb Mo)';
  }

  @override
  String downloading(int percent) {
    return 'Téléchargement… $percent %';
  }

  @override
  String get downloadFailed =>
      'Échec du téléchargement. Vérifiez Internet et réessayez.';

  @override
  String get listenWord => 'Écouter le mot';

  @override
  String get hint => 'Indice';

  @override
  String get memoryMode => 'De mémoire';

  @override
  String get hiddenHelp =>
      'Récitez de mémoire. Chaque mot apparaît quand vous le dites correctement.';

  @override
  String get hiddenWord => 'Mot caché';

  @override
  String get stepListen => '1. Écouter';

  @override
  String get stepRead => '2. Lire';

  @override
  String get stepMemory => '3. De mémoire';

  @override
  String get stepListenHelp => 'Écoutez 3 fois. Suivez chaque mot des yeux.';

  @override
  String get stepListenNoAudio =>
      'Lisez le verset à voix haute 3 fois, lentement.';

  @override
  String get listenAgain => 'Réécouter';

  @override
  String get next => 'Suivant';

  @override
  String get nextAyah => 'Verset suivant';

  @override
  String get finish => 'Terminer';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get memorizedOk => 'Mémorisé !';

  @override
  String get notYet => 'Pas encore. Réessayez : vous allez y arriver.';

  @override
  String nextReview(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Prochaine révision : dans $days jours',
      one: 'Prochaine révision : demain',
    );
    return '$_temp0';
  }

  @override
  String get allDone => 'Bravo !';

  @override
  String get allDoneBody =>
      'Ces versets sont dans vos révisions. Revenez quand ils sont prévus.';

  @override
  String get badgeEarned => 'Nouveau badge !';

  @override
  String get badgeFirstSurah => 'Première sourate mémorisée';

  @override
  String get badgeJuzAmma => 'Juz Amma mémorisé';

  @override
  String get badgeStreak7 => '7 jours de suite';

  @override
  String get badgeStreak30 => '30 jours de suite';

  @override
  String get badgeFirstReview => 'Première révision';

  @override
  String get badgesTitle => 'Badges';

  @override
  String get ok => 'OK';

  @override
  String get statStreak => 'Jours de suite';

  @override
  String get statBest => 'Meilleure série';

  @override
  String get statMemorized => 'Versets mémorisés';

  @override
  String get weekTitle => 'Versets récités, 7 derniers jours';

  @override
  String get masteryTitle => 'Votre carte du Coran';

  @override
  String get masteryNone => 'Pas commencé';

  @override
  String get masteryStarted => 'Commencé';

  @override
  String get masteryMemorized => 'Mémorisé';

  @override
  String get masteryStrong => 'Solide';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSystem => 'Langue du téléphone';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Auto';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsFont => 'Taille du texte coranique';

  @override
  String get settingsTeacher => 'Professeur';

  @override
  String get settingsGoal => 'Objectif quotidien';

  @override
  String get settingsAudio => 'Audio de récitation';

  @override
  String audioOnPhone(String mb) {
    return 'Téléchargé sur ce téléphone : $mb Mo';
  }

  @override
  String downloadAll(String mb) {
    return 'Télécharger toutes les sourates ($mb Mo)';
  }

  @override
  String downloadingAll(int surah) {
    return 'Téléchargement de la sourate $surah…';
  }

  @override
  String get downloadAllHelp =>
      'Utilisez le Wi-Fi. Ensuite, tout l\'audio marche hors ligne.';

  @override
  String get deleteDownloads => 'Supprimer l\'audio téléchargé';

  @override
  String get confirmDelete =>
      'Supprimer l\'audio téléchargé de ce récitant ? L\'audio inclus dans l\'application reste.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get privacy =>
      'Pas de publicité. Pas de compte. Votre voix ne quitte jamais votre téléphone.';

  @override
  String get sourcesTitle => 'Sources';

  @override
  String get sourcesBody =>
      'Texte du Coran : Tanzil.net (Uthmani, sans modification). Récitation : Al-Husary (Muallim) et Mishary Alafasy, via quran.com. Modèle vocal : Quran-Lab (usage gratuit uniquement). Polices : Amiri Quran, Amiri, IBM Plex Sans Arabic.';

  @override
  String get licenses => 'Licences';

  @override
  String get onb1Title =>
      'Apprenez le Coran avec un professeur dans votre téléphone';

  @override
  String get onb1Body =>
      'Lisez, écoutez, récitez et mémorisez. Tout marche sans Internet.';

  @override
  String get onb2Title => 'Le professeur vous écoute';

  @override
  String get onb2Body =>
      'Récitez à voix haute. Chaque mot prend une couleur. À une erreur, le professeur s\'arrête, fait écouter le bon mot, et vous réessayez.';

  @override
  String get onb3Title => 'Un petit objectif chaque jour';

  @override
  String get onb3Body =>
      'Combien de versets voulez-vous réciter chaque jour ? Vous pourrez changer cela plus tard.';

  @override
  String get start => 'Commencer';

  @override
  String get wholeSurah => 'Sourate entière';

  @override
  String get greeting => 'Assalamou alaykoum';

  @override
  String get ayahOfDay => 'Verset du jour';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get startSubtitle => '7 versets courts. Le professeur écoute et aide.';

  @override
  String get more => 'Plus';

  @override
  String get chooseLanguage => 'Choisissez votre langue';

  @override
  String get reciterHusary => 'Mahmoud Khalil Al-Husary (enseignement)';

  @override
  String get reciterHusaryHelp =>
      'Lent et précis. Une pause après chaque verset pour répéter. Idéal pour apprendre.';

  @override
  String get reciterAlafasyHelp =>
      'Récitation fluide. Téléchargement par sourate.';

  @override
  String get bundledNote =>
      'Al-Fatiha et le Juz 30 sont inclus dans l\'application.';

  @override
  String get tapWordHint =>
      'Touchez un mot pour l\'écouter. Touchez le numéro du verset pour plus.';

  @override
  String get reciterHusaryShort => 'Al-Husary (enseignement)';
}
