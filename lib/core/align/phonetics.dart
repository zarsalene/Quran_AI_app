/// The Quran phonetic script of `quran-transcript` (obadx), which is also the
/// label alphabet of the zipformer_p-arabic ASR model.
///
/// A phoneme string is a run of these characters. Repeated characters carry
/// meaning: `ll` is a geminated lam, `aa` is a 2-count madd, `aaaa` is 4 counts,
/// `nnnn` is a geminated noon with ghunna.
library;

enum UnitKind { consonant, shortVowel, longVowel, marker }

/// Tajweed or pronunciation details that never change the letter itself.
/// Differences here are low-confidence hints only.
enum Detail { ikhfa, tasheel, imala, ikhtilas, qalqala }

class PhoneticChar {
  const PhoneticChar(this.kind, this.base, [this.detail]);

  final UnitKind kind;

  /// The character this one collapses to in the skeleton used for alignment.
  final String base;
  final Detail? detail;
}

const String _consonants = 'ءبتثجحخدذرزسشصضطظعغفقكلمنهوي';

final Map<String, PhoneticChar> phoneticChars = {
  for (final c in _consonants.split('')) c: PhoneticChar(UnitKind.consonant, c),
  'ں': const PhoneticChar(UnitKind.consonant, 'ن', Detail.ikhfa), // noon mokhfah
  '۾': const PhoneticChar(UnitKind.consonant, 'م', Detail.ikhfa), // meem mokhfah
  'ٲ': const PhoneticChar(UnitKind.consonant, 'ء', Detail.tasheel), // hamza mosahala
  'َ': const PhoneticChar(UnitKind.shortVowel, 'َ'), // fatha
  'ُ': const PhoneticChar(UnitKind.shortVowel, 'ُ'), // damma
  'ِ': const PhoneticChar(UnitKind.shortVowel, 'ِ'), // kasra
  '۪': const PhoneticChar(UnitKind.shortVowel, 'َ', Detail.imala), // fatha momala
  'ؙ': const PhoneticChar(UnitKind.shortVowel, 'ُ', Detail.ikhtilas), // dama mokhtalasa
  'ا': const PhoneticChar(UnitKind.longVowel, 'ا'),
  'ۦ': const PhoneticChar(UnitKind.longVowel, 'ۦ'), // yaa madd
  'ۥ': const PhoneticChar(UnitKind.longVowel, 'ۥ'), // waw madd
  'ـ': const PhoneticChar(UnitKind.longVowel, 'ا', Detail.imala), // alif momala
  'ڇ': const PhoneticChar(UnitKind.marker, 'ڇ', Detail.qalqala), // qalqala
  'ۜ': const PhoneticChar(UnitKind.marker, 'ۜ'), // sakt
};

/// Letters an ASR model often confuses on phone audio. A substitution inside one
/// of these pairs gives "not sure" instead of "wrong" when
/// [TeacherConfig.confusableIsUnsure] is on.
const List<String> confusablePairs = [
  'ثس', 'ذز', 'ضد', 'ظذ', 'طت', 'صس', 'قك', 'حه', 'عء', 'ظض',
];

bool isConfusable(String a, String b) {
  for (final p in confusablePairs) {
    if ((p[0] == a && p[1] == b) || (p[0] == b && p[1] == a)) return true;
  }
  return false;
}
