import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';

/// Three short screens: what the app does, how the teacher works, a daily goal.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = AppScope.of(context).settings;
    final scheme = Theme.of(context).colorScheme;
    final pages = [
      _Page(
        icon: Icons.auto_stories_rounded,
        title: t.onb1Title,
        body: t.onb1Body,
        extra: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => Column(children: [
            Text(t.chooseLanguage, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (final (code, label) in [('ar', 'العربية'), ('fr', 'Français'), ('en', 'English')])
                ChoiceChip(
                  label: Text(label, style: const TextStyle(fontSize: 16)),
                  selected: settings.locale?.languageCode == code ||
                      (settings.locale == null && Localizations.localeOf(context).languageCode == code),
                  onSelected: (_) => settings.locale = Locale(code),
                ),
            ]),
          ]),
        ),
      ),
      _Page(
        icon: Icons.record_voice_over_rounded,
        title: t.onb2Title,
        body: t.onb2Body,
        extra: Column(children: [
          const SizedBox(height: 16),
          _Legend(color: Colors.green.shade700, text: t.legendCorrect),
          _Legend(color: Colors.orange.shade800, text: t.legendCheck),
          _Legend(color: Colors.red.shade700, text: t.legendMistake),
          const SizedBox(height: 12),
          Text(t.disclaimer, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
      _Page(
        icon: Icons.flag_rounded,
        title: t.onb3Title,
        body: t.onb3Body,
        extra: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            for (final n in [3, 5, 10, 20])
              ChoiceChip(label: Text(t.goalAyahs(n)), selected: settings.dailyGoal == n, onSelected: (_) => settings.dailyGoal = n),
          ]),
        ),
      ),
    ];
    final last = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _page = i),
              children: pages,
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: i == _page ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {
                  if (last) {
                    settings.onboarded = true;
                  } else {
                    _pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                },
                child: Text(last ? t.start : t.next, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.icon, required this.title, required this.body, this.extra});
  final IconData icon;
  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(children: [
        SizedBox(
          height: 220,
          child: HeroPanel(
            padding: EdgeInsets.zero,
            child: Center(
              child: SizedBox.square(
                dimension: 132,
                child: Stack(alignment: Alignment.center, children: [
                  const StarBadge(text: '', size: 132, fill: Color(0x22FFFFFF), stroke: RattilColors.goldLight),
                  Icon(icon, size: 56, color: Colors.white),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        if (extra != null) ...[const SizedBox(height: 20), extra!],
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}
