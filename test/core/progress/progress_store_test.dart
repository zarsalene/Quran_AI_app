import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/core/progress/progress_store.dart';
import 'package:rattil/core/quran/quran_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Al-Fatiha (7 ayahs) and a 3-ayah surah 2, enough for the mastery checks.
  final surahs = [
    for (var s = 1; s <= 114; s++)
      SurahInfo(number: s, name: '$s', tname: '$s', ename: '$s', ayahs: s == 1 ? 7 : 3),
  ];
  var now = DateTime(2026, 10, 27, 9);

  Future<ProgressStore> store() async => ProgressStore(await SharedPreferences.getInstance(), clock: () => now);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 27, 9);
  });

  test('recited ayahs count for today and survive a restart', () async {
    final p = await store();
    p.addRecited(3);
    p.addRecited(2);
    expect(p.recitedToday, 5);
    expect(p.currentStreak, 1);
    final again = await store();
    expect(again.recitedToday, 5);
    expect(again.recitedLastDays(7).last, 5);
  });

  test('listening keeps the streak but does not count for the goal', () async {
    final p = await store();
    p.addListened();
    expect(p.currentStreak, 1);
    expect(p.recitedToday, 0);
  });

  test('a memorized surah earns the first-surah award once', () async {
    final p = await store();
    for (var a = 1; a <= 7; a++) {
      p.reviewAyah(1, a, 5, surahs: surahs);
    }
    expect(p.badges, contains(Award.firstSurah));
    expect(p.takeNewBadges(), [Award.firstSurah]);
    expect(p.takeNewBadges(), isEmpty);
  });

  test('reviews come due on their day, failed ayahs come back to relearn', () async {
    final p = await store();
    p.reviewAyah(1, 1, 5, surahs: surahs);
    p.reviewAyah(1, 2, 1, surahs: surahs);
    expect(p.dueReviews(), isEmpty);
    now = now.add(const Duration(days: 1));
    expect(p.dueReviews(), [(surah: 1, ayah: 1)]);
    expect(p.dueRelearn(), [(surah: 1, ayah: 2)]);
  });

  test('a 7-day streak earns its award', () async {
    final p = await store();
    for (var i = 0; i < 7; i++) {
      p.addRecited(1);
      now = now.add(const Duration(days: 1));
    }
    expect(p.badges, contains(Award.streak7));
    expect(p.bestStreak, 7);
  });

  test('bookmarks toggle and sort in Quran order', () async {
    final p = await store();
    p.toggleBookmark(2, 255);
    p.toggleBookmark(1, 5);
    expect(p.bookmarkList(), [(surah: 1, ayah: 5), (surah: 2, ayah: 255)]);
    p.toggleBookmark(1, 5);
    expect(p.isBookmarked(1, 5), isFalse);
  });

  test('last activity is kept for Continue', () async {
    final p = await store();
    p.setLast(ActivityKind.memorize, 67, 4);
    final again = await store();
    expect(again.last?.kind, ActivityKind.memorize);
    expect(again.last?.surah, 67);
    expect(again.last?.ayah, 4);
  });
}
