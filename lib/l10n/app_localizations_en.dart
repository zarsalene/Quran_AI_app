// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rattil';

  @override
  String get homeStart => 'Start with a short surah';

  @override
  String get homeAll => 'All surahs';

  @override
  String ayahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$_temp0';
  }

  @override
  String get modeStrict => 'Strict';

  @override
  String get modeGentle => 'Gentle';

  @override
  String get modeStrictHelp => 'Stops at a mistake';

  @override
  String get modeGentleHelp => 'Marks mistakes and keeps going';

  @override
  String get teacherLoading => 'Preparing the teacher…';

  @override
  String get tapToStart => 'Tap the microphone and recite';

  @override
  String get listening => 'Listening…';

  @override
  String get stopTitle => 'Check this word';

  @override
  String get stopBody => 'Recite again from this word.';

  @override
  String get repeatFromHere => 'Recite from here';

  @override
  String get jumpedBody =>
      'You moved to another place. Go back to the first word you missed.';

  @override
  String get unsure => 'Not sure. Listen to the reciter.';

  @override
  String get tooNoisy => 'Too noisy. Move to a quieter place.';

  @override
  String get perfect => 'Perfect';

  @override
  String doneWithMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Done. $count mistakes to review.',
      one: 'Done. 1 mistake to review.',
    );
    return '$_temp0';
  }

  @override
  String get doneNotPerfect => 'Done. Check the orange words.';

  @override
  String get again => 'Start again';

  @override
  String get disclaimer =>
      'Automatic feedback can be wrong. It does not replace a qualified teacher.';

  @override
  String get micTitle => 'Microphone';

  @override
  String get micBody =>
      'Rattil listens to your recitation to check it. The sound stays on your phone. It is never sent anywhere.';

  @override
  String get micContinue => 'Continue';

  @override
  String get micDenied =>
      'Rattil needs the microphone to listen to your recitation. Allow it in the phone settings.';

  @override
  String errorStart(String message) {
    return 'The teacher could not start: $message';
  }

  @override
  String get issueMissingWord => 'Missing word';

  @override
  String get issueWrongLetter => 'Wrong letter';

  @override
  String get issueMissingLetter => 'Missing letter';

  @override
  String get issueExtraLetter => 'Extra letter';

  @override
  String get issueExtraWord => 'Extra word';

  @override
  String get issueHarakat => 'Vowel (harakah)';

  @override
  String get issueLongVowel => 'Long vowel';

  @override
  String get issueShadda => 'Shadda';

  @override
  String get issueTajweed => 'Tajweed hint (beta)';

  @override
  String get legendCorrect => 'Correct';

  @override
  String get legendCheck => 'Check';

  @override
  String get legendMistake => 'Mistake';
}
