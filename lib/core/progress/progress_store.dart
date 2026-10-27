import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../quran/quran_repo.dart';
import 'learning.dart';

enum ActivityKind { read, recite, memorize }

/// Where the reader stopped last, for the "Continue" button.
class LastActivity {
  const LastActivity(this.kind, this.surah, this.ayah);
  final ActivityKind kind;
  final int surah;
  final int ayah;

  Map<String, Object> toJson() => {'k': kind.name, 's': surah, 'a': ayah};
  factory LastActivity.fromJson(Map<String, dynamic> j) =>
      LastActivity(ActivityKind.values.byName(j['k'] as String), j['s'] as int, j['a'] as int);
}

enum Award { firstSurah, juzAmma, streak7, streak30, firstReview }

/// The reader's progress, saved on the phone only.
class ProgressStore extends ChangeNotifier {
  ProgressStore(this._prefs, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    final raw = _prefs.getString(_key);
    if (raw != null) _read(jsonDecode(raw) as Map<String, dynamic>);
  }

  static const _key = 'progress.v1';
  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  /// Day → ayahs recited (teacher) that day.
  final Map<String, int> recitedPerDay = {};

  /// Days with any practice: reciting, memorizing, reviewing, or listening.
  final Set<String> activeDays = {};

  /// 's:a' → memorization card.
  final Map<String, MemoCard> cards = {};
  final Set<String> bookmarks = {};
  final Set<Award> badges = {};
  LastActivity? last;
  int bestStreak = 0;

  /// Badges earned since the UI last showed them.
  final List<Award> newBadges = [];

  DateTime get today => _clock();

  void _read(Map<String, dynamic> j) {
    recitedPerDay.addAll({for (final e in ((j['rec'] as Map?) ?? {}).entries) e.key as String: e.value as int});
    activeDays.addAll(List<String>.from((j['days'] as List?) ?? const []));
    cards.addAll({
      for (final e in ((j['cards'] as Map?) ?? {}).entries) e.key as String: MemoCard.fromJson(e.value as Map<String, dynamic>),
    });
    bookmarks.addAll(List<String>.from((j['bm'] as List?) ?? const []));
    badges.addAll([for (final b in (j['badges'] as List?) ?? const []) ...Award.values.where((x) => x.name == b)]);
    final l = j['last'];
    if (l != null) last = LastActivity.fromJson(l as Map<String, dynamic>);
    bestStreak = (j['best'] as int?) ?? 0;
  }

  Future<void> _save() async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'rec': recitedPerDay,
        'days': activeDays.toList()..sort(),
        'cards': {for (final e in cards.entries) e.key: e.value.toJson()},
        'bm': bookmarks.toList(),
        'badges': [for (final b in badges) b.name],
        'last': last?.toJson(),
        'best': bestStreak,
      }),
    );
  }

  static String refKey(int s, int a) => '$s:$a';

  int get currentStreak => streak(activeDays, today);
  int get recitedToday => recitedPerDay[dayKey(today)] ?? 0;

  /// Ayahs recited on each of the last [days] days, oldest first.
  List<int> recitedLastDays(int days) => [
        for (var i = days - 1; i >= 0; i--) recitedPerDay[dayKey(today.subtract(Duration(days: i)))] ?? 0,
      ];

  void _markActive() {
    activeDays.add(dayKey(today));
    final s = currentStreak;
    if (s > bestStreak) bestStreak = s;
    if (bestStreak >= 7) _earn(Award.streak7);
    if (bestStreak >= 30) _earn(Award.streak30);
  }

  void _earn(Award b) {
    if (badges.add(b)) newBadges.add(b);
  }

  /// The teacher heard [count] whole ayahs.
  void addRecited(int count) {
    if (count <= 0) return;
    final k = dayKey(today);
    recitedPerDay[k] = (recitedPerDay[k] ?? 0) + count;
    _markActive();
    notifyListeners();
    _save();
  }

  /// Listening counts as practice for the streak, not for the daily goal.
  void addListened() {
    if (activeDays.contains(dayKey(today))) return;
    _markActive();
    notifyListeners();
    _save();
  }

  void setLast(ActivityKind kind, int surah, int ayah) {
    last = LastActivity(kind, surah, ayah);
    notifyListeners();
    _save();
  }

  MemoCard? card(int s, int a) => cards[refKey(s, a)];

  /// Records a memorization test or review of one ayah.
  void reviewAyah(int s, int a, int grade, {required List<SurahInfo> surahs}) {
    final k = refKey(s, a);
    final wasReview = cards[k]?.memorized ?? false;
    cards[k] = review(cards[k], grade, today);
    if (wasReview && grade >= 3) _earn(Award.firstReview);
    _checkMastery(surahs);
    _markActive();
    notifyListeners();
    _save();
  }

  void _checkMastery(List<SurahInfo> surahs) {
    bool done(int s) => masteryOf(_surahCards(s, surahs[s - 1].ayahs)).index >= Mastery.memorized.index;
    if (surahs.any((s) => done(s.number))) _earn(Award.firstSurah);
    if ([for (var s = 78; s <= 114; s++) s].every(done)) _earn(Award.juzAmma);
  }

  Iterable<MemoCard?> _surahCards(int s, int ayahs) => [for (var a = 1; a <= ayahs; a++) cards[refKey(s, a)]];

  Mastery mastery(SurahInfo s) => masteryOf(_surahCards(s.number, s.ayahs));

  int memorizedAyahs(SurahInfo s) => _surahCards(s.number, s.ayahs).where((c) => c?.memorized ?? false).length;

  /// Memorized ayahs whose review is due, in Quran order.
  List<AyahRef> dueReviews() {
    final t = today;
    final due = [
      for (final e in cards.entries)
        if (e.value.memorized && e.value.isDue(t))
          (surah: int.parse(e.key.split(':')[0]), ayah: int.parse(e.key.split(':')[1])),
    ]..sort(compareRef);
    return due;
  }

  /// Ayahs failed in a test: they come back the next day to learn again.
  List<AyahRef> dueRelearn() {
    final t = today;
    return [
      for (final e in cards.entries)
        if (!e.value.memorized && e.value.isDue(t))
          (surah: int.parse(e.key.split(':')[0]), ayah: int.parse(e.key.split(':')[1])),
    ]..sort(compareRef);
  }

  int get memorizedTotal => cards.values.where((c) => c.memorized).length;

  bool isBookmarked(int s, int a) => bookmarks.contains(refKey(s, a));

  void toggleBookmark(int s, int a) {
    final k = refKey(s, a);
    if (!bookmarks.remove(k)) bookmarks.add(k);
    notifyListeners();
    _save();
  }

  List<AyahRef> bookmarkList() => [
        for (final k in bookmarks) (surah: int.parse(k.split(':')[0]), ayah: int.parse(k.split(':')[1])),
      ]..sort(compareRef);

  List<Award> takeNewBadges() {
    final out = List.of(newBadges);
    newBadges.clear();
    return out;
  }
}
