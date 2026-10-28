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

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get navQuran;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @actionRead.
  ///
  /// In en, this message translates to:
  /// **'Read & listen'**
  String get actionRead;

  /// No description provided for @actionRecite.
  ///
  /// In en, this message translates to:
  /// **'Recite'**
  String get actionRecite;

  /// No description provided for @actionMemorize.
  ///
  /// In en, this message translates to:
  /// **'Memorize'**
  String get actionMemorize;

  /// No description provided for @readHelp.
  ///
  /// In en, this message translates to:
  /// **'Follow the reciter word by word'**
  String get readHelp;

  /// No description provided for @reciteHelp.
  ///
  /// In en, this message translates to:
  /// **'The teacher checks each word'**
  String get reciteHelp;

  /// No description provided for @memorizeHelp.
  ///
  /// In en, this message translates to:
  /// **'Ayah by ayah, with reviews'**
  String get memorizeHelp;

  /// No description provided for @meccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get medinan;

  /// No description provided for @ayahN.
  ///
  /// In en, this message translates to:
  /// **'Ayah {n}'**
  String ayahN(int n);

  /// No description provided for @ayahRange.
  ///
  /// In en, this message translates to:
  /// **'Ayahs {from}–{to}'**
  String ayahRange(int from, int to);

  /// No description provided for @pageN.
  ///
  /// In en, this message translates to:
  /// **'Page {n}'**
  String pageN(int n);

  /// No description provided for @juzN.
  ///
  /// In en, this message translates to:
  /// **'Juz {n}'**
  String juzN(int n);

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal'**
  String get goalTitle;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {goal} ayahs recited'**
  String goalProgress(int done, int goal);

  /// No description provided for @goalDone.
  ///
  /// In en, this message translates to:
  /// **'Goal reached. Well done!'**
  String get goalDone;

  /// No description provided for @goalAyahs.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 ayah} other{{n} ayahs}}'**
  String goalAyahs(int n);

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Start your streak today} =1{1 day in a row} other{{n} days in a row}}'**
  String streakDays(int n);

  /// No description provided for @continueTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueTitle;

  /// No description provided for @startTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with Al-Fatiha'**
  String get startTitle;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTitle;

  /// No description provided for @reviewDue.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 ayah to review} other{{n} ayahs to review}}'**
  String reviewDue(int n);

  /// No description provided for @reviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review today.'**
  String get reviewEmpty;

  /// No description provided for @reviewDone.
  ///
  /// In en, this message translates to:
  /// **'Done: {good} of {total} ayahs remembered well.'**
  String reviewDone(int good, int total);

  /// No description provided for @chooseSurah.
  ///
  /// In en, this message translates to:
  /// **'Choose a surah'**
  String get chooseSurah;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Word, surah, or 2:255'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResults;

  /// No description provided for @tabSurahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get tabSurahs;

  /// No description provided for @tabJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get tabJuz;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet. Tap an ayah to add one.'**
  String get noBookmarks;

  /// No description provided for @pageView.
  ///
  /// In en, this message translates to:
  /// **'Page view'**
  String get pageView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @playFromHere.
  ///
  /// In en, this message translates to:
  /// **'Play from here'**
  String get playFromHere;

  /// No description provided for @repeatAyah.
  ///
  /// In en, this message translates to:
  /// **'Repeat this ayah'**
  String get repeatAyah;

  /// No description provided for @reciteFromHere.
  ///
  /// In en, this message translates to:
  /// **'Recite from here'**
  String get reciteFromHere;

  /// No description provided for @memorizeAyah.
  ///
  /// In en, this message translates to:
  /// **'Memorize this ayah'**
  String get memorizeAyah;

  /// No description provided for @bookmarkAdd.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmarkAdd;

  /// No description provided for @bookmarkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get bookmarkRemove;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @loop.
  ///
  /// In en, this message translates to:
  /// **'Loop the range'**
  String get loop;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @repeatEachTooltip.
  ///
  /// In en, this message translates to:
  /// **'Times each ayah plays'**
  String get repeatEachTooltip;

  /// No description provided for @reciterName.
  ///
  /// In en, this message translates to:
  /// **'Mishary Rashid Alafasy'**
  String get reciterName;

  /// No description provided for @audioMissing.
  ///
  /// In en, this message translates to:
  /// **'The audio of this surah is not on your phone.'**
  String get audioMissing;

  /// No description provided for @downloadSize.
  ///
  /// In en, this message translates to:
  /// **'Download ({mb} MB)'**
  String downloadSize(String mb);

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String downloading(int percent);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Check the internet and try again.'**
  String get downloadFailed;

  /// No description provided for @listenWord.
  ///
  /// In en, this message translates to:
  /// **'Listen to the word'**
  String get listenWord;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @memoryMode.
  ///
  /// In en, this message translates to:
  /// **'From memory'**
  String get memoryMode;

  /// No description provided for @hiddenHelp.
  ///
  /// In en, this message translates to:
  /// **'Recite from memory. Each word shows when you say it correctly.'**
  String get hiddenHelp;

  /// No description provided for @hiddenWord.
  ///
  /// In en, this message translates to:
  /// **'Hidden word'**
  String get hiddenWord;

  /// No description provided for @stepListen.
  ///
  /// In en, this message translates to:
  /// **'1. Listen'**
  String get stepListen;

  /// No description provided for @stepRead.
  ///
  /// In en, this message translates to:
  /// **'2. Read along'**
  String get stepRead;

  /// No description provided for @stepMemory.
  ///
  /// In en, this message translates to:
  /// **'3. From memory'**
  String get stepMemory;

  /// No description provided for @stepListenHelp.
  ///
  /// In en, this message translates to:
  /// **'Listen 3 times. Follow each word with your eyes.'**
  String get stepListenHelp;

  /// No description provided for @stepListenNoAudio.
  ///
  /// In en, this message translates to:
  /// **'Read the ayah aloud 3 times, slowly.'**
  String get stepListenNoAudio;

  /// No description provided for @listenAgain.
  ///
  /// In en, this message translates to:
  /// **'Listen again'**
  String get listenAgain;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nextAyah.
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get nextAyah;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @memorizedOk.
  ///
  /// In en, this message translates to:
  /// **'Memorized!'**
  String get memorizedOk;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet. Try again: you will get it.'**
  String get notYet;

  /// No description provided for @nextReview.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Next review: tomorrow} other{Next review: in {days} days}}'**
  String nextReview(int days);

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get allDone;

  /// No description provided for @allDoneBody.
  ///
  /// In en, this message translates to:
  /// **'These ayahs are now in your reviews. Come back when they are due.'**
  String get allDoneBody;

  /// No description provided for @badgeEarned.
  ///
  /// In en, this message translates to:
  /// **'New badge!'**
  String get badgeEarned;

  /// No description provided for @badgeFirstSurah.
  ///
  /// In en, this message translates to:
  /// **'First surah memorized'**
  String get badgeFirstSurah;

  /// No description provided for @badgeJuzAmma.
  ///
  /// In en, this message translates to:
  /// **'Juz Amma memorized'**
  String get badgeJuzAmma;

  /// No description provided for @badgeStreak7.
  ///
  /// In en, this message translates to:
  /// **'7 days in a row'**
  String get badgeStreak7;

  /// No description provided for @badgeStreak30.
  ///
  /// In en, this message translates to:
  /// **'30 days in a row'**
  String get badgeStreak30;

  /// No description provided for @badgeFirstReview.
  ///
  /// In en, this message translates to:
  /// **'First review'**
  String get badgeFirstReview;

  /// No description provided for @badgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badgesTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'Days in a row'**
  String get statStreak;

  /// No description provided for @statBest.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get statBest;

  /// No description provided for @statMemorized.
  ///
  /// In en, this message translates to:
  /// **'Ayahs memorized'**
  String get statMemorized;

  /// No description provided for @weekTitle.
  ///
  /// In en, this message translates to:
  /// **'Ayahs recited, last 7 days'**
  String get weekTitle;

  /// No description provided for @masteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Quran map'**
  String get masteryTitle;

  /// No description provided for @masteryNone.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get masteryNone;

  /// No description provided for @masteryStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get masteryStarted;

  /// No description provided for @masteryMemorized.
  ///
  /// In en, this message translates to:
  /// **'Memorized'**
  String get masteryMemorized;

  /// No description provided for @masteryStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get masteryStrong;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get languageSystem;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsFont.
  ///
  /// In en, this message translates to:
  /// **'Quran text size'**
  String get settingsFont;

  /// No description provided for @settingsTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get settingsTeacher;

  /// No description provided for @settingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get settingsGoal;

  /// No description provided for @settingsAudio.
  ///
  /// In en, this message translates to:
  /// **'Recitation audio'**
  String get settingsAudio;

  /// No description provided for @audioOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Downloaded on this phone: {mb} MB'**
  String audioOnPhone(String mb);

  /// No description provided for @downloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download all surahs ({mb} MB)'**
  String downloadAll(String mb);

  /// No description provided for @downloadingAll.
  ///
  /// In en, this message translates to:
  /// **'Downloading surah {surah}…'**
  String downloadingAll(int surah);

  /// No description provided for @downloadAllHelp.
  ///
  /// In en, this message translates to:
  /// **'Use Wi-Fi. After this, all audio works offline.'**
  String get downloadAllHelp;

  /// No description provided for @deleteDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete downloaded audio'**
  String get deleteDownloads;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete the downloaded audio of this reciter? Audio included in the app stays.'**
  String get confirmDelete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'No ads. No account. Your voice never leaves your phone.'**
  String get privacy;

  /// No description provided for @sourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sourcesTitle;

  /// No description provided for @sourcesBody.
  ///
  /// In en, this message translates to:
  /// **'Quran text: Tanzil.net (Uthmani, verbatim). Recitation: Al-Husary (Muallim) and Mishary Alafasy, via quran.com. Speech model: Quran-Lab (free use only). Fonts: Amiri Quran, Amiri, IBM Plex Sans Arabic.'**
  String get sourcesBody;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @onb1Title.
  ///
  /// In en, this message translates to:
  /// **'Learn the Quran with a teacher on your phone'**
  String get onb1Title;

  /// No description provided for @onb1Body.
  ///
  /// In en, this message translates to:
  /// **'Read, listen, recite, and memorize. It all works without internet.'**
  String get onb1Body;

  /// No description provided for @onb2Title.
  ///
  /// In en, this message translates to:
  /// **'The teacher listens to you'**
  String get onb2Title;

  /// No description provided for @onb2Body.
  ///
  /// In en, this message translates to:
  /// **'Recite aloud. Each word gets a color. At a mistake, the teacher stops, plays the correct word, and you try again.'**
  String get onb2Body;

  /// No description provided for @onb3Title.
  ///
  /// In en, this message translates to:
  /// **'A small goal every day'**
  String get onb3Title;

  /// No description provided for @onb3Body.
  ///
  /// In en, this message translates to:
  /// **'How many ayahs do you want to recite each day? You can change this later.'**
  String get onb3Body;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @wholeSurah.
  ///
  /// In en, this message translates to:
  /// **'Whole surah'**
  String get wholeSurah;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaykum'**
  String get greeting;

  /// No description provided for @ayahOfDay.
  ///
  /// In en, this message translates to:
  /// **'Ayah of the day'**
  String get ayahOfDay;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @startSubtitle.
  ///
  /// In en, this message translates to:
  /// **'7 short ayahs. The teacher listens and helps.'**
  String get startSubtitle;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @reciterHusary.
  ///
  /// In en, this message translates to:
  /// **'Mahmoud Khalil Al-Husary (teaching)'**
  String get reciterHusary;

  /// No description provided for @reciterHusaryHelp.
  ///
  /// In en, this message translates to:
  /// **'Slow and exact. A pause after each ayah to repeat. Best to learn.'**
  String get reciterHusaryHelp;

  /// No description provided for @reciterAlafasyHelp.
  ///
  /// In en, this message translates to:
  /// **'Flowing recitation. Downloads per surah.'**
  String get reciterAlafasyHelp;

  /// No description provided for @bundledNote.
  ///
  /// In en, this message translates to:
  /// **'Al-Fatiha and Juz 30 are included in the app.'**
  String get bundledNote;

  /// No description provided for @tapWordHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a word to hear it. Tap the ayah number for more.'**
  String get tapWordHint;

  /// No description provided for @reciterHusaryShort.
  ///
  /// In en, this message translates to:
  /// **'Al-Husary (teaching)'**
  String get reciterHusaryShort;
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
