import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/progress/learning.dart';
import '../../core/quran/arabic.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';
import '../reader/mushaf_screen.dart';
import 'search_screen.dart';

/// The Quran tab: surahs, juz, bookmarks, and search.
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.navQuran),
          actions: [
            IconButton(
              tooltip: t.search,
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
            ),
          ],
          bottom: TabBar(tabs: [Tab(text: t.tabSurahs), Tab(text: t.tabJuz), Tab(text: t.bookmarks)]),
        ),
        body: const TabBarView(children: [_SurahList(), _JuzList(), _Bookmarks()]),
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList();

  @override
  Widget build(BuildContext context) {
    final surahs = AppScope.of(context).repo.surahsLoaded;
    return ListenableBuilder(
      listenable: AppScope.of(context).progress,
      builder: (context, _) => ListView.builder(
        itemCount: surahs.length,
        itemBuilder: (context, i) => SurahTile(info: surahs[i]),
      ),
    );
  }
}

class _JuzList extends StatelessWidget {
  const _JuzList();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final repo = AppScope.of(context).repo;
    final meta = repo.metaLoaded;
    return ListView.builder(
      itemCount: 30,
      itemBuilder: (context, i) {
        final start = meta.juz[i];
        final info = repo.surahsLoaded[start.surah - 1];
        return ListTile(
          minVerticalPadding: 12,
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: Text(t.juzN(i + 1)),
          subtitle: Text('${info.name} · ${t.ayahN(start.ayah)} · ${t.pageN(meta.pageOf(start))}'),
          onTap: () => openMushaf(context, meta.pageOf(start)),
        );
      },
    );
  }
}

class _Bookmarks extends StatelessWidget {
  const _Bookmarks();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = AppScope.of(context);
    return ListenableBuilder(
      listenable: s.progress,
      builder: (context, _) {
        final list = s.progress.bookmarkList();
        if (list.isEmpty) {
          return Center(
            child: Padding(padding: const EdgeInsets.all(32), child: Text(t.noBookmarks, textAlign: TextAlign.center)),
          );
        }
        return ListView(children: [
          for (final r in list)
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(s.repo.surahsLoaded[r.surah - 1].name, style: const TextStyle(fontSize: 20)),
              subtitle: Text('${t.ayahN(r.ayah)} · ${t.pageN(s.repo.metaLoaded.pageOf(r))}'),
              onTap: () => openRead(context, r.surah, ayah: r.ayah),
            ),
        ]);
      },
    );
  }
}

/// A surah row with its memorization level.
class SurahTile extends StatelessWidget {
  const SurahTile({super.key, required this.info, this.onTap});
  final SurahInfo info;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mastery = AppScope.of(context).progress.mastery(info);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      minVerticalPadding: 12,
      leading: CircleAvatar(
        backgroundColor: mastery == Mastery.none ? scheme.secondaryContainer : masteryColor(context, mastery),
        foregroundColor: mastery == Mastery.none || mastery == Mastery.started ? scheme.onSecondaryContainer : Colors.white,
        child: Text(isArabicUi(context) ? arabicNumber(info.number) : '${info.number}'),
      ),
      title: Text(info.name, style: const TextStyle(fontFamily: quranFont, fontSize: 22)),
      subtitle: Text(surahSubtitle(context, info)),
      trailing: mastery.index >= Mastery.memorized.index ? Icon(Icons.verified, color: Colors.green.shade600) : null,
      onTap: onTap ?? () => showSurahActions(context, info),
    );
  }
}

/// Choose a surah for one action (from the Today tiles).
class SurahPickerScreen extends StatelessWidget {
  const SurahPickerScreen({super.key, required this.action});
  final SurahAction action;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final surahs = AppScope.of(context).repo.surahsLoaded;
    final order = [...starterSurahs, for (var s = 2; s <= 77; s++) s];
    void go(SurahInfo info) {
      if (action == SurahAction.read) {
        openRead(context, info.number);
      } else {
        showSurahActions(context, info);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.chooseSurah)),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(t.homeStart, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final n in order.take(starterSurahs.length)) SurahTile(info: surahs[n - 1], onTap: () => go(surahs[n - 1])),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(t.homeAll, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final n in order.skip(starterSurahs.length)) SurahTile(info: surahs[n - 1], onTap: () => go(surahs[n - 1])),
      ]),
    );
  }
}
