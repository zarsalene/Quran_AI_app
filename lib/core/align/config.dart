/// Costs and thresholds of the teacher. The defaults are starting points only:
/// `tool/eval` tunes them and EVAL.md records the tuned values.
class TeacherConfig {
  const TeacherConfig({
    this.consonantIndel = 1.0,
    this.vowelIndel = 0.5,
    this.markerIndel = 0.2,
    this.consonantSub = 1.0,
    this.vowelSub = 0.6,
    this.kindSub = 1.5,
    this.geminationMismatch = 0.3,
    this.detailMismatch = 0.05,
    this.repeatCost = 0.5,
    this.repeatBackWords = 3,
    this.leadingNoiseCost = 0.3,
    this.maxLeadingNoiseUnits = 8,
    this.skipFraction = 0.7,
    this.extraWordMinConsonants = 2,
    this.pastMarginUnits = 3,
    this.maddLengthTolerance = 1,
    this.confusableIsUnsure = true,
    this.jumpTailUnits = 12,
    this.jumpTailCost = 0.4,
    this.jumpAcceptCost = 0.25,
    this.confirmEvaluations = 2,
  });

  // Alignment costs.
  final double consonantIndel;
  final double vowelIndel;
  final double markerIndel;
  final double consonantSub;
  final double vowelSub;

  /// Substituting a unit of another kind (a consonant for a vowel).
  final double kindSub;
  final double geminationMismatch;
  final double detailMismatch;

  /// Cost of going back to the start of an earlier word. Kept small: a repeat
  /// is allowed and must not count as a mistake.
  final double repeatCost;
  final int repeatBackWords;

  /// Cost per ASR unit ignored before the first word (noise, a cough).
  /// Must be above 0, or ignoring the whole recitation would be cheapest.
  final double leadingNoiseCost;
  final int maxLeadingNoiseUnits;

  // Classification.
  /// A word with at least this fraction of units deleted is "skipped".
  final double skipFraction;

  /// Extra sounds between words with at least this many consonants are an
  /// extra word. Fewer are an extra letter on the word before.
  final int extraWordMinConsonants;

  /// The reader is past a word once this many units of later words matched.
  final int pastMarginUnits;

  /// Madd length differences up to this many counts are not reported.
  final int maddLengthTolerance;
  final bool confusableIsUnsure;

  // Jump detection.
  /// Number of recent ASR units used to test whether the reader jumped.
  final int jumpTailUnits;

  /// Average cost per recent unit above which a jump search starts.
  final double jumpTailCost;

  /// Average cost per unit at which a search hit is accepted as a jump.
  final double jumpAcceptCost;

  // Strict mode.
  /// A mistake is confirmed when the same issue shows in this many
  /// evaluations in a row, or once the reader is past the word.
  final int confirmEvaluations;
}
