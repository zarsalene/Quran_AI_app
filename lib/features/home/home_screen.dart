import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/progress/progress_store.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';
import '../hifz/review_screen.dart';
import '../quran/quran_screen.dart';

/// Set by CI with --dart-define, so a tester can see which build is installed.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

/// Today: greeting, goal and streak, one "Continue" button, reviews, quick
/// actions, the ayah of the day, and short surahs.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenQuran});
  final VoidCallback? onOpenQuran;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([s.progress, s.settings]),
          builder: (context, _) {
            final surahs = s.surahs;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 0), child: _Hero()),
                const Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 0), child: _ContinueCard()),
                const _ReviewCard(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                  child: Row(children: [
                    _Tile(icon: Icons.mic_rounded, label: t.actionRecite, onTap: () => _pick(context, SurahAction.recite)),
                    _Tile(icon: Icons.school_rounded, label: t.actionMemorize, onTap: () => _pick(context, SurahAction.memorize)),
                    _Tile(icon: Icons.auto_stories_rounded, label: t.actionRead, onTap: () => _pick(context, SurahAction.read)),
                  ]),
                ),
                SectionTitle(t.ayahOfDay),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _AyahOfDay()),
                SectionTitle(t.homeStart,
                    action: TextButton(onPressed: onOpenQuran, child: Text(t.seeAll))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      for (final (i, n) in starterSurahs.take(7).indexed) ...[
                        if (i > 0) const Divider(indent: 76),
                        SurahTile(info: surahs[n - 1]),
                      ],
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: OutlinedButton(onPressed: onOpenQuran, child: Text(t.homeAll)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _pick(BuildContext context, SurahAction action) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SurahPickerScreen(action: action)));
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = AppScope.of(context);
    final done = s.progress.recitedToday, goal = s.settings.dailyGoal;
    final streak = s.progress.currentStreak;
    final reached = done >= goal;
    return HeroPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.greeting, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
              const SizedBox(height: 2),
              Text(t.appTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
            ]),
          ),
          Text('رتّل', style: TextStyle(fontFamily: titleFont, fontWeight: FontWeight.w700, fontSize: 30, color: RattilColors.goldLight.withValues(alpha: 0.95))),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          SizedBox.square(
            dimension: 76,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: goal == 0 ? 0 : (done / goal).clamp(0, 1),
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  color: RattilColors.goldLight,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              reached
                  ? const Icon(Icons.check_rounded, color: RattilColors.goldLight, size: 34)
                  : Text('$done/$goal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.goalTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              Text(reached ? t.goalDone : t.goalProgress(done, goal),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: streak > 0 ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.local_fire_department_rounded, size: 18, color: streak > 0 ? const Color(0xFFFFA24A) : Colors.white54),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(t.streakDays(streak),
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(appVersion, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
        ),
      ]),
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
    final info = s.surahs[(last?.surah ?? 1) - 1];
    final title = last == null ? t.startTitle : t.continueTitle;
    final kind = switch (last?.kind) {
      ActivityKind.read => t.actionRead,
      ActivityKind.memorize => t.actionMemorize,
      _ => t.actionRecite,
    };
    final subtitle = last == null ? t.startSubtitle : '$kind · ${t.ayahN(last.ayah)}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ),
            Text(info.name,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: titleFont, fontWeight: FontWeight.w700, fontSize: 22, color: scheme.primary)),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ReviewScreen())),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.replay_circle_filled_rounded, size: 40, color: scheme.onSecondaryContainer),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.reviewTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSecondaryContainer)),
                  Text(t.reviewDue(n), style: TextStyle(color: scheme.onSecondaryContainer)),
                ]),
              ),
              Icon(Icons.arrow_forward_rounded, color: scheme.onSecondaryContainer),
            ]),
          ),
        ),
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
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: scheme.outlineVariant)),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Column(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                  child: Icon(icon, size: 26, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 8),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13.5)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// One short ayah from Juz 30 each day, verbatim from the data.
class _AyahOfDay extends StatelessWidget {
  const _AyahOfDay();

  static AyahRef pick(DateTime day, List<SurahInfo> surahs) {
    final d = DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final s = 78 + d % 37;
    return (surah: s, ayah: (d * 7) % surahs[s - 1].ayahs + 1);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = AppLocalizations.of(context);
    final ref = pick(s.progress.today, s.surahs);
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<QSurah>(
      future: s.text(ref.surah),
      builder: (context, snap) {
        final surah = snap.data;
        if (surah == null) return const SizedBox(height: 120);
        final ayah = surah.ayahs[ref.ayah - 1];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openRead(context, ref.surah, ayah: ref.ayah),
            child: Container(
              decoration: BoxDecoration(
                border: BorderDirectional(start: BorderSide(color: scheme.secondary, width: 4)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text.rich(
                  TextSpan(children: [
                    for (final w in ayah.words) TextSpan(text: '${w.mark == null ? w.text : '${w.text} ${w.mark}'} '),
                    WidgetSpan(alignment: PlaceholderAlignment.middle, child: AyahEndMarker(number: ayah.number, size: 22)),
                  ]),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: quranFont, fontSize: 24, height: 2.0, color: scheme.onSurface),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.auto_stories_rounded, size: 16, color: scheme.secondary),
                  const SizedBox(width: 6),
                  Text('${s.surahs[ref.surah - 1].name} · ${t.ayahN(ref.ayah)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}
