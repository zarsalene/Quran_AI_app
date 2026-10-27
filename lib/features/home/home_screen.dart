import 'package:flutter/material.dart';

import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../teacher/recite_screen.dart';

/// Set by CI with --dart-define, so a tester can see which build is installed.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

/// Al-Fatiha, then Juz 30 from its shortest surahs at the end, so a new
/// reader gets quick wins first.
const starterSurahs = [1, 114, 113, 112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101, 100, 99, 98, 97,
  96, 95, 94, 93, 92, 91, 90, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repo});
  final QuranRepo repo;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<SurahInfo>> _surahs = widget.repo.surahs();
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
      body: FutureBuilder<List<SurahInfo>>(
        future: _surahs,
        builder: (context, snap) {
          final all = snap.data;
          if (all == null) return const Center(child: CircularProgressIndicator());
          final byNumber = {for (final s in all) s.number: s};
          final others = all.where((s) => !starterSurahs.contains(s.number)).toList();
          return ListView(
            children: [
              _Header(t.homeStart),
              for (final n in starterSurahs) _SurahTile(info: byNumber[n]!, repo: widget.repo),
              _Header(t.homeAll),
              if (!_showAll)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(onPressed: () => setState(() => _showAll = true), child: Text(t.homeAll)),
                )
              else
                for (final s in others) _SurahTile(info: s, repo: widget.repo),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.info, required this.repo});
  final SurahInfo info;
  final QuranRepo repo;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    return ListTile(
      minVerticalPadding: 12,
      leading: CircleAvatar(child: Text('${info.number}')),
      title: Text(info.name, style: const TextStyle(fontSize: 22)),
      subtitle: Text(arabicUi ? t.ayahCount(info.ayahs) : '${info.tname} · ${t.ayahCount(info.ayahs)}'),
      trailing: const Icon(Icons.mic),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ReciteScreen(repo: repo, info: info)),
      ),
    );
  }
}
