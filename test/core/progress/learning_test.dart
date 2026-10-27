import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/core/progress/learning.dart';

void main() {
  final day = DateTime(2026, 10, 27); // a Tuesday

  group('review (SM-2)', () {
    test('first success: due tomorrow, then in 3 days, then growing', () {
      var c = review(null, 5, day);
      expect(c.reps, 1);
      expect(c.due, '2026-10-28');
      c = review(c, 5, day);
      expect(c.interval, 3);
      c = review(c, 4, day);
      expect(c.interval, greaterThan(3));
      expect(c.memorized, isTrue);
    });

    test('a failed review forgets the ayah: back tomorrow, one lapse', () {
      var c = review(review(review(null, 5, day), 5, day), 5, day);
      c = review(c, 2, day);
      expect(c.memorized, isFalse);
      expect(c.interval, 1);
      expect(c.lapses, 1);
    });

    test('ease never goes below 1.3', () {
      var c = review(null, 3, day);
      for (var i = 0; i < 20; i++) {
        c = review(c, 3, day);
      }
      expect(c.ease, greaterThanOrEqualTo(1.3));
    });

    test('intervals stop growing at one year', () {
      var c = review(null, 5, day);
      for (var i = 0; i < 30; i++) {
        c = review(c, 5, day);
      }
      expect(c.interval, lessThanOrEqualTo(365));
    });
  });

  group('gradeFor', () {
    test('perfect is 5, marks only 4, one mistake 3, more 2', () {
      expect(gradeFor(perfect: true, mistakes: 0), 5);
      expect(gradeFor(perfect: false, mistakes: 0), 4);
      expect(gradeFor(perfect: false, mistakes: 1), 3);
      expect(gradeFor(perfect: false, mistakes: 3), 2);
    });

    test('each hint takes one point off, never below 2', () {
      expect(gradeFor(perfect: true, mistakes: 0, hints: 1), 4);
      expect(gradeFor(perfect: false, mistakes: 1, hints: 5), 2);
    });
  });

  group('streak', () {
    Set<String> days(List<int> back) => {for (final b in back) dayKey(day.subtract(Duration(days: b)))};

    test('counts days in a row ending today', () {
      expect(streak(days([0, 1, 2]), day), 3);
    });

    test('today not done yet: the streak from yesterday is still alive', () {
      expect(streak(days([1, 2]), day), 2);
    });

    test('nothing yesterday or today: no streak', () {
      expect(streak(days([2, 3]), day), 0);
    });

    test('one missed day per week is forgiven', () {
      // Tue, Mon, (Sun missed), Sat, Fri
      expect(streak(days([0, 1, 3, 4]), day), 4);
    });

    test('two missed days in the same week break the streak', () {
      // Sun 1 Nov 2026 back to Mon 26 Oct: Wed 28 and Fri 30 missed.
      final sun = DateTime(2026, 11, 1);
      final active = {for (final d in [1, 31, 29, 27, 26]) dayKey(d == 1 ? sun : DateTime(2026, 10, d))};
      expect(streak(active, sun), 3); // Sun, Sat, (Fri frozen), Thu, then Wed breaks
    });

    test('two missed days in a row break the streak', () {
      expect(streak(days([0, 3, 4]), day), 1);
    });
  });

  group('mastery', () {
    MemoCard card({int reps = 1, int interval = 1}) => MemoCard(reps: reps, interval: interval, due: '2026-10-28');

    test('levels from none to strong', () {
      expect(masteryOf([null, null]), Mastery.none);
      expect(masteryOf([card(), null]), Mastery.started);
      expect(masteryOf([card(), card(reps: 0)]), Mastery.started);
      expect(masteryOf([card(), card()]), Mastery.memorized);
      expect(masteryOf([card(interval: 30), card(interval: 21)]), Mastery.strong);
    });
  });
}
