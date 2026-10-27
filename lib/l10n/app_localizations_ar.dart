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
}
