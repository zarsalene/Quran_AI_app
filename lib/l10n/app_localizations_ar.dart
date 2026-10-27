// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'رتّل';

  @override
  String get homeStart => 'ابدأ بسورة قصيرة';

  @override
  String get homeAll => 'كل السور';

  @override
  String ayahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count آية',
      few: '$count آيات',
      two: 'آيتان',
      one: 'آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get modeStrict => 'صارم';

  @override
  String get modeGentle => 'هادئ';

  @override
  String get modeStrictHelp => 'يتوقف عند الخطأ';

  @override
  String get modeGentleHelp => 'يعلّم الأخطاء ويكمل';

  @override
  String get teacherLoading => 'جارٍ تجهيز المعلّم…';

  @override
  String get tapToStart => 'اضغط على الميكروفون واقرأ';

  @override
  String get listening => 'أستمع…';

  @override
  String get stopTitle => 'راجع هذه الكلمة';

  @override
  String get stopBody => 'أعد القراءة من هذه الكلمة.';

  @override
  String get repeatFromHere => 'اقرأ من هنا';

  @override
  String get jumpedBody => 'انتقلت إلى موضع آخر. ارجع إلى أول كلمة فاتتك.';

  @override
  String get unsure => 'لست متأكدًا. استمع إلى القارئ.';

  @override
  String get tooNoisy => 'الضجيج عالٍ. انتقل إلى مكان أهدأ.';

  @override
  String get perfect => 'ممتاز';

  @override
  String doneWithMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'انتهيت. $count خطأ للمراجعة.',
      few: 'انتهيت. $count أخطاء للمراجعة.',
      two: 'انتهيت. خطآن للمراجعة.',
      one: 'انتهيت. خطأ واحد للمراجعة.',
    );
    return '$_temp0';
  }

  @override
  String get doneNotPerfect => 'انتهيت. راجع الكلمات البرتقالية.';

  @override
  String get again => 'ابدأ من جديد';

  @override
  String get disclaimer => 'قد يخطئ التصحيح الآلي. ولا يغني عن معلّم مؤهَّل.';

  @override
  String get micTitle => 'الميكروفون';

  @override
  String get micBody =>
      'يستمع رتّل إلى تلاوتك ليصحّحها. يبقى الصوت على هاتفك ولا يُرسَل إلى أي مكان.';

  @override
  String get micContinue => 'متابعة';

  @override
  String get micDenied =>
      'يحتاج رتّل إلى الميكروفون ليستمع إلى تلاوتك. اسمح به من إعدادات الهاتف.';

  @override
  String errorStart(String message) {
    return 'تعذّر تشغيل المعلّم: $message';
  }

  @override
  String get issueMissingWord => 'كلمة ناقصة';

  @override
  String get issueWrongLetter => 'حرف خطأ';

  @override
  String get issueMissingLetter => 'حرف ناقص';

  @override
  String get issueExtraLetter => 'حرف زائد';

  @override
  String get issueExtraWord => 'كلمة زائدة';

  @override
  String get issueHarakat => 'حركة';

  @override
  String get issueLongVowel => 'مدّ';

  @override
  String get issueShadda => 'شدّة';

  @override
  String get issueTajweed => 'تنبيه تجويد (تجريبي)';

  @override
  String get legendCorrect => 'صحيح';

  @override
  String get legendCheck => 'راجع';

  @override
  String get legendMistake => 'خطأ';

  @override
  String get navToday => 'اليوم';

  @override
  String get navQuran => 'القرآن';

  @override
  String get navProgress => 'التقدّم';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get actionRead => 'اقرأ واستمع';

  @override
  String get actionRecite => 'سمِّع';

  @override
  String get actionMemorize => 'احفظ';

  @override
  String get readHelp => 'تابع القارئ كلمةً كلمة';

  @override
  String get reciteHelp => 'المعلّم يراجع كل كلمة';

  @override
  String get memorizeHelp => 'آيةً آية، مع المراجعة';

  @override
  String get meccan => 'مكية';

  @override
  String get medinan => 'مدنية';

  @override
  String ayahN(int n) {
    return 'الآية $n';
  }

  @override
  String ayahRange(int from, int to) {
    return 'الآيات $from–$to';
  }

  @override
  String pageN(int n) {
    return 'الصفحة $n';
  }

  @override
  String juzN(int n) {
    return 'الجزء $n';
  }

  @override
  String get goalTitle => 'هدف اليوم';

  @override
  String goalProgress(int done, int goal) {
    return '$done من $goal آيات';
  }

  @override
  String get goalDone => 'حقّقت هدفك. أحسنت!';

  @override
  String goalAyahs(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n آية',
      many: '$n آية',
      few: '$n آيات',
      two: 'آيتان',
      one: 'آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يوم متتالٍ',
      many: '$n يومًا متتاليًا',
      few: '$n أيام متتالية',
      two: 'يومان متتاليان',
      one: 'يوم واحد متتالٍ',
      zero: 'ابدأ سلسلتك اليوم',
    );
    return '$_temp0';
  }

  @override
  String get continueTitle => 'تابع';

  @override
  String get startTitle => 'ابدأ بالفاتحة';

  @override
  String get reviewTitle => 'المراجعة';

  @override
  String reviewDue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n آية للمراجعة',
      many: '$n آية للمراجعة',
      few: '$n آيات للمراجعة',
      two: 'آيتان للمراجعة',
      one: 'آية واحدة للمراجعة',
    );
    return '$_temp0';
  }

  @override
  String get reviewEmpty => 'لا مراجعة اليوم.';

  @override
  String reviewDone(int good, int total) {
    return 'انتهيت: حفظت $good من $total جيدًا.';
  }

  @override
  String get chooseSurah => 'اختر سورة';

  @override
  String get search => 'بحث';

  @override
  String get searchHint => 'كلمة أو سورة أو 2:255';

  @override
  String get searchNoResults => 'لا نتائج';

  @override
  String get tabSurahs => 'السور';

  @override
  String get tabJuz => 'الأجزاء';

  @override
  String get bookmarks => 'العلامات';

  @override
  String get noBookmarks => 'لا علامات بعد. اضغط على آية لإضافة علامة.';

  @override
  String get pageView => 'عرض الصفحات';

  @override
  String get listView => 'عرض القائمة';

  @override
  String get playFromHere => 'استمع من هنا';

  @override
  String get repeatAyah => 'كرّر هذه الآية';

  @override
  String get reciteFromHere => 'سمِّع من هنا';

  @override
  String get memorizeAyah => 'احفظ هذه الآية';

  @override
  String get bookmarkAdd => 'أضف علامة';

  @override
  String get bookmarkRemove => 'احذف العلامة';

  @override
  String get play => 'تشغيل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get stop => 'إيقاف';

  @override
  String get loop => 'كرّر المقطع';

  @override
  String get speed => 'السرعة';

  @override
  String get repeatEachTooltip => 'عدد مرات كل آية';

  @override
  String get reciterName => 'مشاري راشد العفاسي';

  @override
  String get audioMissing => 'صوت هذه السورة غير موجود على هاتفك.';

  @override
  String downloadSize(String mb) {
    return 'تنزيل ($mb م.ب)';
  }

  @override
  String downloading(int percent) {
    return 'جارٍ التنزيل… $percent٪';
  }

  @override
  String get downloadFailed => 'فشل التنزيل. تحقّق من الإنترنت وأعد المحاولة.';

  @override
  String get listenWord => 'استمع إلى الكلمة';

  @override
  String get hint => 'تلميح';

  @override
  String get memoryMode => 'من الذاكرة';

  @override
  String get hiddenHelp => 'سمِّع من حفظك. تظهر كل كلمة حين تنطقها صحيحة.';

  @override
  String get hiddenWord => 'كلمة مخفية';

  @override
  String get stepListen => '١. استمع';

  @override
  String get stepRead => '٢. اقرأ';

  @override
  String get stepMemory => '٣. من الذاكرة';

  @override
  String get stepListenHelp => 'استمع ثلاث مرات. تابع كل كلمة بعينك.';

  @override
  String get stepListenNoAudio => 'اقرأ الآية بصوت مسموع ثلاث مرات، ببطء.';

  @override
  String get listenAgain => 'استمع مرة أخرى';

  @override
  String get next => 'التالي';

  @override
  String get nextAyah => 'الآية التالية';

  @override
  String get finish => 'إنهاء';

  @override
  String get tryAgain => 'أعد المحاولة';

  @override
  String get memorizedOk => 'حفظتها!';

  @override
  String get notYet => 'ليس بعد. أعد المحاولة، ستنجح بإذن الله.';

  @override
  String nextReview(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'المراجعة القادمة: بعد $days يومًا',
      few: 'المراجعة القادمة: بعد $days أيام',
      two: 'المراجعة القادمة: بعد يومين',
      one: 'المراجعة القادمة: غدًا',
    );
    return '$_temp0';
  }

  @override
  String get allDone => 'أحسنت!';

  @override
  String get allDoneBody =>
      'أُضيفت هذه الآيات إلى مراجعاتك. عُد إليها في موعدها.';

  @override
  String get badgeEarned => 'وسام جديد!';

  @override
  String get badgeFirstSurah => 'أول سورة محفوظة';

  @override
  String get badgeJuzAmma => 'حفظ جزء عمّ';

  @override
  String get badgeStreak7 => '٧ أيام متتالية';

  @override
  String get badgeStreak30 => '٣٠ يومًا متتاليًا';

  @override
  String get badgeFirstReview => 'أول مراجعة';

  @override
  String get badgesTitle => 'الأوسمة';

  @override
  String get ok => 'حسنًا';

  @override
  String get statStreak => 'أيام متتالية';

  @override
  String get statBest => 'أفضل سلسلة';

  @override
  String get statMemorized => 'آيات محفوظة';

  @override
  String get weekTitle => 'الآيات المسمّعة، آخر ٧ أيام';

  @override
  String get masteryTitle => 'خريطة حفظك';

  @override
  String get masteryNone => 'لم تبدأ';

  @override
  String get masteryStarted => 'بدأت';

  @override
  String get masteryMemorized => 'محفوظة';

  @override
  String get masteryStrong => 'متقنة';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageSystem => 'لغة الهاتف';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get settingsFont => 'حجم خط المصحف';

  @override
  String get settingsTeacher => 'المعلّم';

  @override
  String get settingsGoal => 'الهدف اليومي';

  @override
  String get settingsAudio => 'صوت التلاوة';

  @override
  String audioOnPhone(String mb) {
    return 'الفاتحة وجزء عمّ مضمّنان. المُنزَّل: $mb م.ب.';
  }

  @override
  String downloadAll(String mb) {
    return 'تنزيل كل السور ($mb م.ب)';
  }

  @override
  String downloadingAll(int surah) {
    return 'جارٍ تنزيل السورة $surah…';
  }

  @override
  String get downloadAllHelp =>
      'استخدم الواي فاي. بعدها يعمل كل الصوت دون إنترنت.';

  @override
  String get deleteDownloads => 'احذف الصوت المُنزَّل';

  @override
  String get confirmDelete => 'حذف كل الصوت المُنزَّل؟ تبقى الفاتحة وجزء عمّ.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get privacy => 'بلا إعلانات. بلا حساب. صوتك لا يغادر هاتفك أبدًا.';

  @override
  String get sourcesTitle => 'المصادر';

  @override
  String get sourcesBody =>
      'نص القرآن: موقع تنزيل (الرسم العثماني، دون تغيير). التلاوة: مشاري العفاسي عبر quran.com. نموذج الصوت: Quran-Lab (للاستخدام المجاني فقط). الخط: Amiri Quran.';

  @override
  String get licenses => 'التراخيص';

  @override
  String get onb1Title => 'تعلّم القرآن مع معلّم في هاتفك';

  @override
  String get onb1Body => 'اقرأ واستمع وسمِّع واحفظ. كل ذلك يعمل دون إنترنت.';

  @override
  String get onb2Title => 'المعلّم يستمع إليك';

  @override
  String get onb2Body =>
      'اقرأ بصوت مسموع. تتلوّن كل كلمة. عند الخطأ يتوقف المعلّم، ويُسمعك الكلمة الصحيحة، ثم تعيد.';

  @override
  String get onb3Title => 'هدف صغير كل يوم';

  @override
  String get onb3Body => 'كم آية تريد أن تسمّع كل يوم؟ يمكنك تغيير ذلك لاحقًا.';

  @override
  String get start => 'ابدأ';
}
