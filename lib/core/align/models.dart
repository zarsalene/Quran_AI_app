/// How sure the teacher is that an issue is a real mistake.
///
/// high: a word is missing or extra, or a letter is wrong. Strict mode stops.
/// medium: harakat, long vowel, or shadda. Orange mark, no stop by default.
/// low: tajweed (madd length, ghunna, ikhfa, qalqala). Beta hint, never stops.
enum Severity { high, medium, low }

enum IssueType {
  missingWord(Severity.high),
  wrongLetter(Severity.high),
  missingLetter(Severity.high),
  extraLetter(Severity.high),
  extraWord(Severity.high),
  harakat(Severity.medium),
  longVowel(Severity.medium),
  shadda(Severity.medium),
  maddLength(Severity.low),
  ghunna(Severity.low),
  ikhfa(Severity.low),
  qalqala(Severity.low),
  otherTajweed(Severity.low);

  const IssueType(this.severity);
  final Severity severity;
}

class Issue {
  const Issue(this.type, {this.expectedUnit, this.heard, this.unsure = false});

  final IssueType type;

  /// Index of the expected unit (in the ExpectedStream), if any.
  final int? expectedUnit;

  /// What the ASR heard instead, as phonetic characters, if any.
  final String? heard;

  /// The ASR may have misheard (a confusable letter pair). The UI says
  /// "Not sure. Listen to the reciter" and never "wrong".
  final bool unsure;

  Severity get severity => type.severity;

  /// Stable key used to check that two evaluations found the same mistake.
  String get signature => '${type.name}:$expectedUnit:$heard';

  @override
  String toString() => 'Issue(${type.name}, unit $expectedUnit, heard $heard${unsure ? ', unsure' : ''})';
}

enum WordStatus {
  /// Not reached yet.
  pending,

  /// Every sound matched at the word level. May still carry medium or low marks.
  correct,

  /// At least one high-severity issue.
  wrong,

  /// Only high issues the ASR may have misheard.
  unsure,

  /// The reader went past this word without saying it.
  skipped,

  /// The reader jumped to another place; this word was passed over by the jump.
  jumped,
}

class WordResult {
  const WordResult({
    required this.word,
    required this.status,
    this.issues = const [],
    this.isPast = false,
    this.hypStart = -1,
    this.hypEnd = -1,
  });

  /// Word index in the ExpectedStream.
  final int word;
  final WordStatus status;
  final List<Issue> issues;

  /// True when the reader has clearly moved on to a later word.
  final bool isPast;

  /// Range of ASR units [hypStart, hypEnd) aligned to this word, -1 if none.
  final int hypStart;
  final int hypEnd;

  bool get hasHigh => issues.any((i) => i.severity == Severity.high && !i.unsure);
  bool get hasMedium => issues.any((i) => i.severity == Severity.medium);
  bool get hasLow => issues.any((i) => i.severity == Severity.low);

  @override
  String toString() => 'W$word ${status.name}${isPast ? ' past' : ''} $issues';
}
