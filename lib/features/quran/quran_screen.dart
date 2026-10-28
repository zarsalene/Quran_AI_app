import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/progress/learning.dart';
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(112),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
                    child: SizedBox(
                      height: 52,
                      child: Row(children: [
                        const SizedBox(width: 16),
                        Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(t.searchHint, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ]),
                    ),
                  ),
                ),
              ),
              TabBar(tabs: [Tab(text: t.tabSurahs), Tab(text: t.tabJuz), Tab(text: t.bookmarks)]),
            ]),
          ),
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
    final surahs = AppScope.of(context).surahs;
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
          leading: StarBadge(text: '${i + 1}'),
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
              title: Text(s.surahs[r.surah - 1].name, style: const TextStyle(fontSize: 20)),
              subtitle: Text('${t.ayahN(r.ayah)} · ${t.pageN(s.meta.pageOf(r))}'),
              onTap: () => openRead(context, r.surah, ayah: r.ayah),
            ),
        ]);
      },
    );
  }
}

/// A surah row: number in a star, name and meaning, the Arabic name in
/// calligraphy, and the memorization level.
class SurahTile extends StatelessWidget {
  const SurahTile({super.key, required this.info, this.onTap});
  final SurahInfo info;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mastery = AppScope.of(context).progress.mastery(info);
    final scheme = Theme.of(context).colorScheme;
    final arabic = isArabicUi(context);
    final t = AppLocalizations.of(context);
    final started = mastery != Mastery.none;
    return InkWell(
      onTap: onTap ?? () => showSurahActions(context, info),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          StarBadge(
            text: '${info.number}',
            fill: started ? masteryColor(context, mastery) : null,
            textColor: mastery.index >= Mastery.memorized.index ? Colors.white : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(arabic ? info.name : info.tname,
                  style: arabic
                      ? const TextStyle(fontFamily: titleFont, fontWeight: FontWeight.w700, fontSize: 20, height: 1.4)
                      : Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Row(children: [
                Icon(info.meccan ? Icons.mosque_outlined : Icons.location_city_outlined, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    arabic ? surahSubtitle(context, info) : '${info.ename} · ${t.ayahCount(info.ayahs)}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ]),
            ]),
          ),
          if (mastery.index >= Mastery.memorized.index)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Icon(Icons.verified_rounded, color: scheme.primary, size: 20),
            ),
          if (!arabic)
            Text(info.name,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: titleFont, fontWeight: FontWeight.w700, fontSize: 22, color: scheme.primary)),
        ]),
      ),
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
    final surahs = AppScope.of(context).surahs;
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
