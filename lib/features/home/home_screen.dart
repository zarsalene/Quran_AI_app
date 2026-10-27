import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/progress/progress_store.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';
import '../hifz/review_screen.dart';
import '../quran/quran_screen.dart';

/// Set by CI with --dart-define, so a tester can see which build is installed.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

/// Today: goal, streak, one "Continue" button, reviews, and short surahs.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenQuran});
  final VoidCallback? onOpenQuran;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Text(appVersion, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([s.progress, s.settings]),
        builder: (context, _) {
          final surahs = s.repo.surahsLoaded;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const _GoalCard(),
              const _ContinueCard(),
              const _ReviewCard(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(children: [
                  _Tile(icon: Icons.mic, label: t.actionRecite, onTap: () => _pick(context, SurahAction.recite)),
                  _Tile(icon: Icons.psychology_alt, label: t.actionMemorize, onTap: () => _pick(context, SurahAction.memorize)),
                  _Tile(icon: Icons.menu_book, label: t.actionRead, onTap: () => _pick(context, SurahAction.read)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(t.homeStart, style: Theme.of(context).textTheme.titleLarge),
              ),
              for (final n in starterSurahs.take(12)) SurahTile(info: surahs[n - 1]),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(onPressed: onOpenQuran, child: Text(t.homeAll)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _pick(BuildContext context, SurahAction action) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SurahPickerScreen(action: action)));
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = AppScope.of(context);
    final done = s.progress.recitedToday, goal = s.settings.dailyGoal;
    final streak = s.progress.currentStreak;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          SizedBox.square(
            dimension: 72,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: (done / goal).clamp(0, 1),
                  strokeWidth: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              Icon(done >= goal ? Icons.check : Icons.flag, color: scheme.primary, size: 30),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.goalTitle, style: Theme.of(context).textTheme.titleMedium),
              Text(done >= goal ? t.goalDone : t.goalProgress(done, goal),
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.local_fire_department, color: streak > 0 ? Colors.deepOrange : scheme.outline),
                const SizedBox(width: 4),
                Text(t.streakDays(streak)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = AppScope.of(context);
    final last = s.progress.last;
    final scheme = Theme.of(context).colorScheme;
    final info = s.repo.surahsLoaded[(last?.surah ?? 1) - 1];
    final title = last == null ? t.startTitle : t.continueTitle;
    final kind = switch (last?.kind) {
      ActivityKind.read => t.actionRead,
      ActivityKind.memorize => t.actionMemorize,
      _ => t.actionRecite,
    };
    final subtitle = last == null ? surahSubtitle(context, info) : '$kind · ${info.name} · ${t.ayahN(last.ayah)}';
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: scheme.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (last == null) {
            showSurahActions(context, info);
            return;
          }
          switch (last.kind) {
            case ActivityKind.read:
              openRead(context, last.surah, ayah: last.ayah);
            case ActivityKind.recite:
              openRecite(context, last.surah, last.ayah, info.ayahs);
            case ActivityKind.memorize:
              openMemorize(context, last.surah, last.ayah, info.ayahs);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Icon(Icons.play_circle_fill, size: 48, color: scheme.onPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.9))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = AppScope.of(context).progress;
    final n = p.dueReviews().length + p.dueRelearn().length;
    if (n == 0) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ListTile(
        leading: const Icon(Icons.replay, size: 32),
        title: Text(t.reviewTitle),
        subtitle: Text(t.reviewDue(n)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ReviewScreen())),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
              child: Column(children: [
                Icon(icon, size: 32, color: scheme.onSecondaryContainer),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
