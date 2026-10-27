/// Arabic text normalization, for search only. Displayed text is never
/// normalized.
library;

final _marks = RegExp('[ؐ-ًؚ-ٟۖ-ۭـ]');

/// Folds letter forms and strips harakat, Quran marks and tatweel, so a query
/// typed on a phone keyboard matches the Uthmani text.
///
/// The dagger alif (ـٰ) is written as a full alif when [daggerAsAlif] is true
/// (ٱلرَّحْمَـٰنِ → الرحمان) and dropped otherwise (→ الرحمن). Search tries both.
String normalizeArabic(String s, {bool daggerAsAlif = false}) {
  final b = StringBuffer();
  for (final r in s.replaceAll('ٰ', daggerAsAlif ? 'ا' : '').replaceAll(_marks, '').runes) {
    b.writeCharCode(switch (r) {
      0x0671 || 0x0622 || 0x0623 || 0x0625 || 0x0672 || 0x0673 => 0x0627, // ٱ آ أ إ → ا
      0x0649 || 0x06CC => 0x064A, // ى → ي
      0x0629 => 0x0647, // ة → ه
      0x0624 => 0x0648, // ؤ → و
      0x0626 => 0x064A, // ئ → ي
      _ => r,
    });
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// 255 → ٢٥٥
String arabicNumber(int n) => n.toString().split('').map((d) => _arabicDigits[int.parse(d)]).join();
