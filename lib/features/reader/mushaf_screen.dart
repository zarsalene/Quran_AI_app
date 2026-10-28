import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/progress/progress_store.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';
import 'ayah_widgets.dart';
import 'reader_screen.dart';

void openMushaf(BuildContext context, int page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MushafScreen(initialPage: page)));
}

/// The Madani mushaf, page by page (604 pages, same ayahs per page).
class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key, required this.initialPage});
  final int initialPage;

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late final _services = AppScope.of(context);
  late final _pages = PageController(initialPage: widget.initialPage - 1);
  late int _page = widget.initialPage;

  /// First ayah of [page].
  AyahRef _start(int page) => _services.meta.pages[page - 1];

  @override
  void dispose() {
    final r = _start(_page);
    _services.progress.setLast(ActivityKind.read, r.surah, r.ayah);
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final meta = _services.meta;
    final start = _start(_page);
    final info = _services.surahs[start.surah - 1];
    return Scaffold(
      appBar: AppBar(
        title: Text('${t.pageN(_page)} · ${t.juzN(meta.juzOf(start))}'),
        actions: [
          IconButton(
            tooltip: t.listView,
            icon: const Icon(Icons.view_agenda),
            onPressed: () {
              _services.settings.pageView = false;
              Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                  builder: (_) => ReaderScreen(surah: start.surah, initialAyah: start.ayah)));
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        // Arabic books turn to the left: page 2 is on the left of page 1.
        reverse: Directionality.of(context) == TextDirection.ltr,
        itemCount: 604,
        onPageChanged: (i) => setState(() => _page = i + 1),
        itemBuilder: (context, i) => _Page(page: i + 1),
      ),
      bottomNavigationBar: AudioBar(surah: start.surah, ayahs: info.ayahs, startAyah: () => start.ayah),
    );
  }
}

/// The ayahs of one page, grouped by surah.
class _Page extends StatefulWidget {
  const _Page({required this.page});
  final int page;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  List<(QSurah, List<QAyah>)>? _blocks;
  final List<TapGestureRecognizer> _taps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = AppScope.of(context).repo;
    final pages = repo.metaLoaded.pages;
    final from = pages[widget.page - 1];
    final to = widget.page < 604 ? pages[widget.page] : (surah: 115, ayah: 1);
    final blocks = <(QSurah, List<QAyah>)>[];
    for (var s = from.surah; s <= to.surah && s <= 114; s++) {
      final surah = await repo.surah(s);
      final ayahs = [
        for (final a in surah.ayahs)
          if (compareRef((surah: s, ayah: a.number), from) >= 0 && compareRef((surah: s, ayah: a.number), to) < 0) a,
      ];
      if (ayahs.isNotEmpty) blocks.add((surah, ayahs));
    }
    if (mounted) setState(() => _blocks = blocks);
  }

  void _clearTaps() {
    for (final r in _taps) {
      r.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _clearTaps();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _blocks;
    if (blocks == null) return const Center(child: CircularProgressIndicator());
    final s = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([s.player, s.settings]),
      builder: (context, _) {
        _clearTaps();
        final style = quranStyle(context);
        final scheme = Theme.of(context).colorScheme;
        final children = <Widget>[];
        for (final (surah, ayahs) in blocks) {
          final info = s.surahs[surah.number - 1];
          if (ayahs.first.number == 1) {
            children.add(SurahHeader(info: info));
            if (surah.basmala != null) {
              children.add(Text(surah.basmala!,
                  textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: style.copyWith(color: scheme.primary)));
            }
          }
          final spans = <InlineSpan>[];
          for (final a in ayahs) {
            final taps = wordRecognizers(context, surah.number, a);
            _taps.addAll(taps);
            spans.addAll(ayahSpans(context, a,
                style: style,
                playingWord: heardWord(s.player, surah.number, a.number),
                playingAyah: isPlaying(s.player, surah.number, a.number),
                wordTaps: taps,
                onMarker: () => showAyahActions(context, surah.number, a.number, surahAyahs: surah.ayahs.length)));
          }
          children.add(Text.rich(TextSpan(children: spans), textDirection: TextDirection.rtl, textAlign: TextAlign.justify));
        }
        children.add(Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Center(child: AyahEndMarker(number: widget.page, size: 26)),
        ));
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.secondary, width: 1.4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border.all(color: scheme.secondary.withValues(alpha: 0.5), width: 0.8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        );
      },
    );
  }
}
