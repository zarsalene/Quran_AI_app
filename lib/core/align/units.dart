import 'phonetics.dart';

/// One sound in a phoneme string: a run of the same phonetic character.
class PUnit {
  const PUnit(this.kind, this.base, this.length, this.details, {this.start = 0, this.end = 0});

  final UnitKind kind;
  final String base;

  /// Run length. For a consonant: 1 plain, 2 geminated (shadda), more is
  /// ghunna. For a long vowel: the madd count (2, 4, 6).
  final int length;
  final Set<Detail> details;

  /// Character offsets [start, end) in the source string (spaces excluded).
  final int start;
  final int end;

  bool get isGeminated => kind == UnitKind.consonant && length >= 2;

  /// Skeleton identity used for alignment. Madd length, ghunna length and
  /// tajweed details are ignored here and compared later as low-level details.
  bool sameBase(PUnit o) => kind == o.kind && base == o.base;

  PUnit _extend(int run, Set<Detail> more, int newEnd) =>
      PUnit(kind, base, length + run, {...details, ...more}, start: start, end: newEnd);

  @override
  String toString() => '$base×$length${details.isEmpty ? '' : details}';
}

class UnknownPhonemeError extends FormatException {
  UnknownPhonemeError(String char, String source)
      : super('Unknown phoneme U+${char.codeUnitAt(0).toRadixString(16)}', source);
}

/// Splits a phoneme string into units. Whitespace is dropped first, so the
/// expected text (which has word spaces) and the ASR output (which has none)
/// give the same units. A qalqala marker becomes a detail of the consonant
/// before it, and a base letter next to its variant (noon then noon mokhfah)
/// merges into one unit.
List<PUnit> toUnits(String phonemes) {
  final chars = phonemes.replaceAll(RegExp(r'\s'), '').split('');
  final units = <PUnit>[];
  var i = 0;
  while (i < chars.length) {
    final c = chars[i];
    final pc = phoneticChars[c];
    if (pc == null) throw UnknownPhonemeError(c, phonemes);
    var j = i + 1;
    while (j < chars.length && chars[j] == c) {
      j++;
    }
    final run = j - i;
    final details = {if (pc.detail != null) pc.detail!};
    final prev = units.isEmpty ? null : units.last;
    if (pc.detail == Detail.qalqala && prev != null && prev.kind == UnitKind.consonant) {
      units[units.length - 1] = prev._extend(0, details, j);
    } else if (prev != null && pc.kind != UnitKind.marker && prev.kind == pc.kind && prev.base == pc.base) {
      units[units.length - 1] = prev._extend(run, details, j);
    } else {
      units.add(PUnit(pc.kind, pc.base, run, details, start: i, end: j));
    }
    i = j;
  }
  return units;
}

/// The expected phonemes of a word range, tokenized as one stream.
class ExpectedStream {
  ExpectedStream._(this.units, this.unitWord, this.wordFirstUnit, this.wordCount);

  /// [wordPhonemes] holds one phoneme string per word, in reading order.
  factory ExpectedStream(List<String> wordPhonemes) {
    final charWord = <int>[];
    for (var w = 0; w < wordPhonemes.length; w++) {
      final n = wordPhonemes[w].replaceAll(RegExp(r'\s'), '').length;
      charWord.addAll(List.filled(n, w));
    }
    final units = toUnits(wordPhonemes.join());
    // A unit that spans a word boundary (idgham of the same letter) belongs to
    // the word where it starts.
    final unitWord = [for (final u in units) charWord[u.start]];
    final firstUnit = List<int>.filled(wordPhonemes.length + 1, units.length);
    for (var k = units.length - 1; k >= 0; k--) {
      firstUnit[unitWord[k]] = k;
    }
    // A word whose sounds were fully merged into the previous word has no
    // unit of its own; give it the next word's start so ranges stay ordered.
    for (var w = wordPhonemes.length - 1; w >= 0; w--) {
      if (firstUnit[w] > firstUnit[w + 1]) firstUnit[w] = firstUnit[w + 1];
    }
    return ExpectedStream._(units, unitWord, firstUnit, wordPhonemes.length);
  }

  final List<PUnit> units;
  final List<int> unitWord;

  /// wordFirstUnit[w] is the index of word w's first unit. The last entry is
  /// units.length, so word w spans [wordFirstUnit[w], wordFirstUnit[w + 1]).
  final List<int> wordFirstUnit;
  final int wordCount;

  int wordStart(int w) => wordFirstUnit[w];
  int wordEnd(int w) => wordFirstUnit[w + 1];
}
