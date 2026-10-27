import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/progress/learning.dart';
import '../../core/progress/progress_store.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';

/// Streak, last 7 days, the Quran map, and badges.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.navProgress)),
      body: ListenableBuilder(
        listenable: Listenable.merge([s.progress, s.settings]),
        builder: (context, _) {
          final p = s.progress;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              _Stat(icon: Icons.local_fire_department, color: Colors.deepOrange, value: '${p.currentStreak}', label: t.statStreak),
              _Stat(icon: Icons.emoji_events, color: Colors.amber.shade700, value: '${p.bestStreak}', label: t.statBest),
              _Stat(icon: Icons.psychology_alt, color: Colors.green.shade700, value: '${p.memorizedTotal}', label: t.statMemorized),
            ]),
            const SizedBox(height: 20),
            Text(t.weekTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _WeekChart(values: p.recitedLastDays(7), goal: s.settings.dailyGoal),
            const SizedBox(height: 24),
            Text(t.masteryTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _MasteryMap(),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 4, children: [
              for (final m in Mastery.values)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: masteryColor(context, m), borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 4),
                  Text(_masteryLabel(t, m), style: Theme.of(context).textTheme.bodySmall),
                ]),
            ]),
            const SizedBox(height: 24),
            Text(t.badgesTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final b in Award.values) _BadgeChip(badge: b, earned: p.badges.contains(b)),
            ]),
          ]);
        },
      ),
    );
  }
}

String _masteryLabel(AppLocalizations t, Mastery m) => switch (m) {
      Mastery.none => t.masteryNone,
      Mastery.started => t.masteryStarted,
      Mastery.memorized => t.masteryMemorized,
      Mastery.strong => t.masteryStrong,
    };

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(children: [
            Icon(icon, color: color, size: 30),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.values, required this.goal});
  final List<int> values;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = AppScope.of(context).progress.today;
    final top = [goal, ...values].reduce((a, b) => a > b ? a : b).toDouble();
    final locale = Localizations.localeOf(context);
    final days = MaterialLocalizations.of(context).narrowWeekdays;
    return SizedBox(
      height: 140,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${values[i]}', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Container(
                  height: 90 * (values[i] / top).clamp(0.03, 1),
                  decoration: BoxDecoration(
                    color: values[i] >= goal ? scheme.primary : scheme.primary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  days[today.subtract(Duration(days: values.length - 1 - i)).weekday % 7],
                  style: Theme.of(context).textTheme.labelSmall,
                  locale: locale,
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _MasteryMap extends StatelessWidget {
  const _MasteryMap();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(spacing: 4, runSpacing: 4, children: [
        for (final info in s.repo.surahsLoaded)
          Tooltip(
            message: '${info.number}. ${info.name}',
            child: InkWell(
              onTap: () => showSurahActions(context, info),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: masteryColor(context, s.progress.mastery(info)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${info.number}', style: const TextStyle(fontSize: 10)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.earned});
  final Award badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(badgeIcon(badge), color: earned ? Colors.amber.shade700 : scheme.outline),
      label: Text(badgeLabel(t, badge)),
      backgroundColor: earned ? Colors.amber.withValues(alpha: 0.15) : null,
      labelStyle: TextStyle(color: earned ? null : scheme.outline),
    );
  }
}
