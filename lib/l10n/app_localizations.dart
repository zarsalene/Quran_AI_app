import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rattil'**
  String get appTitle;

  /// No description provided for @homeStart.
  ///
  /// In en, this message translates to:
  /// **'Start with a short surah'**
  String get homeStart;

  /// No description provided for @homeAll.
  ///
  /// In en, this message translates to:
  /// **'All surahs'**
  String get homeAll;

  /// No description provided for @ayahCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String ayahCount(int count);

  /// No description provided for @modeStrict.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get modeStrict;

  /// No description provided for @modeGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get modeGentle;

  /// No description provided for @modeStrictHelp.
  ///
  /// In en, this message translates to:
  /// **'Stops at a mistake'**
  String get modeStrictHelp;

  /// No description provided for @modeGentleHelp.
  ///
  /// In en, this message translates to:
  /// **'Marks mistakes and keeps going'**
  String get modeGentleHelp;

  /// No description provided for @teacherLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing the teacher…'**
  String get teacherLoading;

  /// No description provided for @tapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone and recite'**
  String get tapToStart;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listening;

  /// No description provided for @stopTitle.
  ///
  /// In en, this message translates to:
  /// **'Check this word'**
  String get stopTitle;

  /// No description provided for @stopBody.
  ///
  /// In en, this message translates to:
  /// **'Recite again from this word.'**
  String get stopBody;

  /// No description provided for @repeatFromHere.
  ///
  /// In en, this message translates to:
  /// **'Recite from here'**
  String get repeatFromHere;

  /// No description provided for @jumpedBody.
  ///
  /// In en, this message translates to:
  /// **'You moved to another place. Go back to the first word you missed.'**
  String get jumpedBody;

  /// No description provided for @unsure.
  ///
  /// In en, this message translates to:
  /// **'Not sure. Listen to the reciter.'**
  String get unsure;

  /// No description provided for @tooNoisy.
  ///
  /// In en, this message translates to:
  /// **'Too noisy. Move to a quieter place.'**
  String get tooNoisy;

  /// No description provided for @perfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect'**
  String get perfect;

  /// No description provided for @doneWithMistakes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Done. 1 mistake to review.} other{Done. {count} mistakes to review.}}'**
  String doneWithMistakes(int count);

  /// No description provided for @doneNotPerfect.
  ///
  /// In en, this message translates to:
  /// **'Done. Check the orange words.'**
  String get doneNotPerfect;

  /// No description provided for @again.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get again;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Automatic feedback can be wrong. It does not replace a qualified teacher.'**
  String get disclaimer;

  /// No description provided for @micTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get micTitle;

  /// No description provided for @micBody.
  ///
  /// In en, this message translates to:
  /// **'Rattil listens to your recitation to check it. The sound stays on your phone. It is never sent anywhere.'**
  String get micBody;

  /// No description provided for @micContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get micContinue;

  /// No description provided for @micDenied.
  ///
  /// In en, this message translates to:
  /// **'Rattil needs the microphone to listen to your recitation. Allow it in the phone settings.'**
  String get micDenied;

  /// No description provided for @errorStart.
  ///
  /// In en, this message translates to:
  /// **'The teacher could not start: {message}'**
  String errorStart(String message);

  /// No description provided for @issueMissingWord.
  ///
  /// In en, this message translates to:
  /// **'Missing word'**
  String get issueMissingWord;

  /// No description provided for @issueWrongLetter.
  ///
  /// In en, this message translates to:
  /// **'Wrong letter'**
  String get issueWrongLetter;

  /// No description provided for @issueMissingLetter.
  ///
  /// In en, this message translates to:
  /// **'Missing letter'**
  String get issueMissingLetter;

  /// No description provided for @issueExtraLetter.
  ///
  /// In en, this message translates to:
  /// **'Extra letter'**
  String get issueExtraLetter;

  /// No description provided for @issueExtraWord.
  ///
  /// In en, this message translates to:
  /// **'Extra word'**
  String get issueExtraWord;

  /// No description provided for @issueHarakat.
  ///
  /// In en, this message translates to:
  /// **'Vowel (harakah)'**
  String get issueHarakat;

  /// No description provided for @issueLongVowel.
  ///
  /// In en, this message translates to:
  /// **'Long vowel'**
  String get issueLongVowel;

  /// No description provided for @issueShadda.
  ///
  /// In en, this message translates to:
  /// **'Shadda'**
  String get issueShadda;

  /// No description provided for @issueTajweed.
  ///
  /// In en, this message translates to:
  /// **'Tajweed hint (beta)'**
  String get issueTajweed;

  /// No description provided for @legendCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get legendCorrect;

  /// No description provided for @legendCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get legendCheck;

  /// No description provided for @legendMistake.
  ///
  /// In en, this message translates to:
  /// **'Mistake'**
  String get legendMistake;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
