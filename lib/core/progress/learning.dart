/// Pure learning logic: spaced repetition (SM-2), grades, streaks.
library;

/// A calendar day as 'yyyy-mm-dd', in local time.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDay(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

/// Memorization state of one ayah (SM-2).
class MemoCard {
  const MemoCard({this.reps = 0, this.ease = 2.5, this.interval = 0, required this.due, this.lapses = 0});

  /// Successful reviews in a row. 0 = not memorized (new or forgotten).
  final int reps;
  final double ease;

  /// Days until the next review.
  final int interval;
  final String due;
  final int lapses;

  bool get memorized => reps > 0;

  /// Strong: reviewed well over three weeks.
  bool get strong => interval >= 21;

  bool isDue(DateTime today) => due.compareTo(dayKey(today)) <= 0;

  Map<String, Object> toJson() => {'r': reps, 'e': ease, 'i': interval, 'd': due, 'l': lapses};

  factory MemoCard.fromJson(Map<String, dynamic> j) => MemoCard(
        reps: j['r'] as int,
        ease: (j['e'] as num).toDouble(),
        interval: j['i'] as int,
        due: j['d'] as String,
        lapses: (j['l'] as int?) ?? 0,
      );
}

/// SM-2 with short first steps (1, then 3 days), for memorizing ayahs.
/// [grade] is 0..5: below 3 the ayah is forgotten and comes back tomorrow.
MemoCard review(MemoCard? c, int grade, DateTime today) {
  final old = c ?? MemoCard(due: dayKey(today));
  final q = grade.clamp(0, 5);
  final ease = (old.ease + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)).clamp(1.3, 3.0);
  if (q < 3) {
    return MemoCard(reps: 0, ease: ease, interval: 1, due: dayKey(_date(today).add(const Duration(days: 1))),
        lapses: old.lapses + (old.memorized ? 1 : 0));
  }
  final reps = old.reps + 1;
  final grown = (old.interval * ease).round();
  final interval = switch (reps) { 1 => 1, 2 => 3, _ => (grown > old.interval ? grown : old.interval + 1).clamp(1, 365) };
  return MemoCard(reps: reps, ease: ease, interval: interval, due: dayKey(_date(today).add(Duration(days: interval))),
      lapses: old.lapses);
}

/// Grade of one recitation from the teacher's result.
///
/// 5 perfect, 4 only vowel or tajweed marks, 3 one mistake, 2 more. Each
/// hint (a peek at a hidden word) takes one point off, down to 2.
int gradeFor({required bool perfect, required int mistakes, int hints = 0}) {
  final base = perfect ? 5 : switch (mistakes) { 0 => 4, 1 => 3, _ => 2 };
  return mistakes > 1 ? base : (base - hints).clamp(2, 5);
}

/// Days in a row with practice, ending today or yesterday.
///
/// One missed day per calendar week (Monday to Sunday) is forgiven (a
/// "freeze"), so one busy day does not break a long streak.
int streak(Set<String> activeDays, DateTime today) {
  var d = _date(today);
  if (!activeDays.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
  var n = 0;
  final frozenWeeks = <int>{};
  int week(DateTime x) => _date(x).subtract(Duration(days: x.weekday - 1)).millisecondsSinceEpoch;
  while (true) {
    if (activeDays.contains(dayKey(d))) {
      n++;
    } else {
      final before = d.subtract(const Duration(days: 1));
      if (n == 0 || !activeDays.contains(dayKey(before)) || !frozenWeeks.add(week(d))) break;
    }
    d = d.subtract(const Duration(days: 1));
  }
  return n;
}

/// Memorization level of a surah, for the mastery map.
enum Mastery {
  none,

  /// Some ayahs memorized.
  started,

  /// Every ayah memorized.
  memorized,

  /// Every ayah strong (reviewed well over three weeks).
  strong,
}

Mastery masteryOf(Iterable<MemoCard?> ayahCards) {
  final cards = ayahCards.toList();
  if (cards.isEmpty || cards.every((c) => c == null || !c.memorized)) return Mastery.none;
  if (cards.any((c) => c == null || !c.memorized)) return Mastery.started;
  return cards.every((c) => c!.strong) ? Mastery.strong : Mastery.memorized;
}
