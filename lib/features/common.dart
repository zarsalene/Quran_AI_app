import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/progress/learning.dart';
import '../core/progress/progress_store.dart';
import '../core/quran/arabic.dart';
import '../core/quran/quran_repo.dart';
import '../l10n/app_localizations.dart';
import '../ui/ornaments.dart';
import '../ui/theme.dart';
import 'hifz/memorize_screen.dart';
import 'reader/mushaf_screen.dart';
import 'reader/reader_screen.dart';
import 'teacher/recite_screen.dart';

export '../ui/ornaments.dart';
export '../ui/theme.dart';

/// Al-Fatiha, then Juz 30 from its shortest surahs at the end, so a new
/// reader gets quick wins first.
const starterSurahs = [1, 114, 113, 112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101, 100, 99, 98, 97,
  96, 95, 94, 93, 92, 91, 90, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78];

bool isArabicUi(BuildContext context) => Localizations.localeOf(context).languageCode == 'ar';

/// "Al-Faatiha · 7 ayahs" (the Arabic name is shown as the title already).
String surahSubtitle(BuildContext context, SurahInfo info) {
  final t = AppLocalizations.of(context);
  final kind = info.meccan ? t.meccan : t.medinan;
  return isArabicUi(context)
      ? '$kind · ${t.ayahCount(info.ayahs)}'
      : '${info.tname} · ${t.ayahCount(info.ayahs)}';
}

/// End-of-ayah marker with the number in Arabic digits: ﴿٥﴾
String ayahMarker(int n) => '﴿${arabicNumber(n)}﴾';

enum SurahAction { read, recite, memorize }

/// Opens the reader in the view the user chose last (pages or list).
void openRead(BuildContext context, int surah, {int ayah = 1}) {
  final s = AppScope.of(context);
  final page = s.repo.metaLoaded.pageOf((surah: surah, ayah: ayah));
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => s.settings.pageView ? MushafScreen(initialPage: page) : ReaderScreen(surah: surah, initialAyah: ayah),
  ));
}

void openRecite(BuildContext context, int surah, int from, int to) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReciteScreen(surah: surah, from: from, to: to)));
}

void openMemorize(BuildContext context, int surah, int from, int to) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MemorizeScreen(surah: surah, from: from, to: to)));
}

/// The three ways into a surah. Recite and memorize take an ayah range.
Future<void> showSurahActions(BuildContext context, SurahInfo info, {int from = 1, int? to}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SurahActionsSheet(info: info, from: from, to: to ?? info.ayahs),
  );
}

class _SurahActionsSheet extends StatefulWidget {
  const _SurahActionsSheet({required this.info, required this.from, required this.to});
  final SurahInfo info;
  final int from;
  final int to;

  @override
  State<_SurahActionsSheet> createState() => _SurahActionsSheetState();
}

class _SurahActionsSheetState extends State<_SurahActionsSheet> {
  late RangeValues _range = RangeValues(widget.from.toDouble(), widget.to.toDouble());

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final info = widget.info;
    final from = _range.start.round(), to = _range.end.round();
    void go(SurahAction a) {
      final nav = Navigator.of(context);
      nav.pop();
      switch (a) {
        case SurahAction.read:
          openRead(nav.context, info.number, ayah: from);
        case SurahAction.recite:
          openRecite(nav.context, info.number, from, to);
        case SurahAction.memorize:
          openMemorize(nav.context, info.number, from, to);
      }
    }

    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SurahBanner(name: info.name, subtitle: surahSubtitle(context, info)),
            if (info.ayahs > 1) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.format_list_numbered_rtl, color: scheme.secondary, size: 20),
                const SizedBox(width: 8),
                Text(rangeLabel(t, from, to), style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (from != 1 || to != info.ayahs)
                  TextButton(
                    onPressed: () => setState(() => _range = RangeValues(1, info.ayahs.toDouble())),
                    child: Text(t.wholeSurah),
                  ),
              ]),
              RangeSlider(
                values: _range,
                min: 1,
                max: info.ayahs.toDouble(),
                divisions: info.ayahs - 1,
                labels: RangeLabels('$from', '$to'),
                onChanged: (v) => setState(() => _range = v),
              ),
            ],
            const SizedBox(height: 4),
            _ActionButton(icon: Icons.mic_rounded, label: t.actionRecite, help: t.reciteHelp, primary: true,
                onTap: () => go(SurahAction.recite)),
            Row(children: [
              Expanded(
                child: _ActionButton(icon: Icons.school_rounded, label: t.actionMemorize, help: t.memorizeHelp,
                    onTap: () => go(SurahAction.memorize)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(icon: Icons.auto_stories_rounded, label: t.actionRead, help: t.readHelp,
                    onTap: () => go(SurahAction.read)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

String rangeLabel(AppLocalizations t, int from, int to) => from == to ? t.ayahN(from) : t.ayahRange(from, to);

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.help, required this.onTap, this.primary = false});
  final IconData icon;
  final String label;
  final String help;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = primary ? Colors.white : scheme.onSurface;
    final content = primary
        ? Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
                Text(help, style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.85))),
              ]),
            ),
            Icon(Icons.arrow_forward_rounded, color: fg),
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 26, color: scheme.primary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: fg)),
            Text(help, maxLines: 2, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ]);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: primary ? scheme.primary : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(children: [
            if (primary) const Positioned.fill(child: StarPattern(opacity: 0.06, cell: 36)),
            Padding(padding: const EdgeInsets.all(16), child: content),
          ]),
        ),
      ),
    );
  }
}

/// Surah title banner shown above its first ayah.
class SurahHeader extends StatelessWidget {
  const SurahHeader({super.key, required this.info});
  final SurahInfo info;

  @override
  Widget build(BuildContext context) => SurahBanner(name: info.name, subtitle: surahSubtitle(context, info));
}

/// Mastery colors, from not started to strong.
Color masteryColor(BuildContext context, Mastery m) {
  final scheme = Theme.of(context).colorScheme;
  return switch (m) {
    Mastery.none => scheme.surfaceContainerHighest,
    Mastery.started => RattilColors.goldLight,
    Mastery.memorized => RattilColors.emeraldLight,
    Mastery.strong => RattilColors.emerald,
  };
}

String badgeLabel(AppLocalizations t, Award b) => switch (b) {
      Award.firstSurah => t.badgeFirstSurah,
      Award.juzAmma => t.badgeJuzAmma,
      Award.streak7 => t.badgeStreak7,
      Award.streak30 => t.badgeStreak30,
      Award.firstReview => t.badgeFirstReview,
    };

IconData badgeIcon(Award b) => switch (b) {
      Award.firstSurah => Icons.star,
      Award.juzAmma => Icons.workspace_premium,
      Award.streak7 => Icons.local_fire_department,
      Award.streak30 => Icons.whatshot,
      Award.firstReview => Icons.replay_circle_filled,
    };

/// Shows badges earned since the last call, one small celebration each.
Future<void> celebrateNewBadges(BuildContext context) async {
  final progress = AppScope.of(context).progress;
  for (final b in progress.takeNewBadges()) {
    if (!context.mounted) return;
    final t = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Icon(badgeIcon(b), size: 72, color: Colors.amber.shade700),
        ),
        title: Text(t.badgeEarned, textAlign: TextAlign.center),
        content: Text(badgeLabel(t, b), textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.titleLarge),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(t.ok))],
      ),
    );
  }
}

/// Download prompt for a surah whose audio is not on the phone.
class AudioDownloadTile extends StatelessWidget {
  const AudioDownloadTile({super.key, required this.surah});
  final int surah;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final audio = AppScope.of(context).audio;
    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        final p = audio.downloading[surah];
        final failed = audio.downloadErrors.containsKey(surah);
        final mb = (audio.surah(surah).bytes / 1e6).toStringAsFixed(0);
        return ListTile(
          leading: p == null ? const Icon(Icons.download) : const SizedBox.square(dimension: 24, child: CircularProgressIndicator()),
          title: Text(p == null ? t.audioMissing : t.downloading((p * 100).round())),
          subtitle: failed && p == null ? Text(t.downloadFailed, style: TextStyle(color: Theme.of(context).colorScheme.error)) : null,
          trailing: p == null ? FilledButton.tonal(onPressed: () => audio.download(surah), child: Text(t.downloadSize(mb))) : null,
        );
      },
    );
  }
}
