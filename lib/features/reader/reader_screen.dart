import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../app_scope.dart';
import '../../core/progress/progress_store.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';
import 'ayah_widgets.dart';
import 'mushaf_screen.dart';

/// Read and listen: one surah, ayah by ayah, with the reciter.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.surah, this.initialAyah = 1});
  final int surah;
  final int initialAyah;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  QSurah? _surah;
  final _scroll = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  int? _followedAyah;
  late final _services = AppScope.of(context);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _services.repo.surah(widget.surah);
    if (!mounted) return;
    setState(() => _surah = s);
    _services.player.addListener(_follow);
  }

  /// Keeps the playing ayah on screen.
  void _follow() {
    final p = _services.player;
    final a = p.ayah;
    if (!mounted || p.surah != widget.surah || a == null || a == _followedAyah || !_scroll.isAttached) return;
    _followedAyah = a;
    final visible = _positions.itemPositions.value.where((x) => x.itemLeadingEdge >= 0 && x.itemTrailingEdge <= 1);
    if (visible.any((x) => x.index == a)) return;
    _scroll.scrollTo(index: a, duration: const Duration(milliseconds: 400), alignment: 0.1);
  }

  /// The first ayah on screen (item 0 is the header).
  int _firstVisibleAyah() {
    final items = _positions.itemPositions.value.where((x) => x.itemTrailingEdge > 0).map((x) => x.index);
    if (items.isEmpty) return widget.initialAyah;
    final i = items.reduce((a, b) => a < b ? a : b);
    return i.clamp(1, _surah?.ayahs.length ?? 1);
  }

  @override
  void dispose() {
    _services.player.removeListener(_follow);
    if (_surah != null) _services.progress.setLast(ActivityKind.read, widget.surah, _firstVisibleAyah());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final info = _services.repo.surahsLoaded[widget.surah - 1];
    final surah = _surah;
    return Scaffold(
      appBar: AppBar(
        title: Text(info.name, style: const TextStyle(fontFamily: quranFont, fontSize: 24)),
        actions: [
          IconButton(
            tooltip: t.actionRecite,
            icon: const Icon(Icons.mic),
            onPressed: () => openRecite(context, widget.surah, _firstVisibleAyah(), info.ayahs),
          ),
          IconButton(
            tooltip: t.pageView,
            icon: const Icon(Icons.auto_stories),
            onPressed: () {
              final page = _services.repo.metaLoaded.pageOf((surah: widget.surah, ayah: _firstVisibleAyah()));
              _services.settings.pageView = true;
              Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => MushafScreen(initialPage: page)));
            },
          ),
        ],
      ),
      body: surah == null
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: Listenable.merge([_services.player, _services.settings, _services.progress]),
              builder: (context, _) => ScrollablePositionedList.builder(
                itemScrollController: _scroll,
                itemPositionsListener: _positions,
                initialScrollIndex: widget.initialAyah == 1 ? 0 : widget.initialAyah,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: surah.ayahs.length + 1,
                itemBuilder: (context, i) => i == 0 ? _Header(info: info, surah: surah) : _AyahTile(surah: surah, ayah: surah.ayahs[i - 1]),
              ),
            ),
      bottomNavigationBar: AudioBar(surah: widget.surah, ayahs: info.ayahs, startAyah: _firstVisibleAyah),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.info, required this.surah});
  final SurahInfo info;
  final QSurah surah;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(children: [
        SurahHeader(info: info),
        if (surah.basmala != null)
          Text(surah.basmala!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: quranStyle(context).copyWith(color: Theme.of(context).colorScheme.primary)),
      ]),
    );
  }
}

class _AyahTile extends StatefulWidget {
  const _AyahTile({required this.surah, required this.ayah});
  final QSurah surah;
  final QAyah ayah;

  @override
  State<_AyahTile> createState() => _AyahTileState();
}

class _AyahTileState extends State<_AyahTile> {
  late final _taps = wordRecognizers(context, widget.surah.number, widget.ayah);

  void _actions() =>
      showAyahActions(context, widget.surah.number, widget.ayah.number, surahAyahs: widget.surah.ayahs.length);

  @override
  void dispose() {
    for (final r in _taps) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.player;
    final playing = isPlaying(p, widget.surah.number, widget.ayah.number);
    final marked = s.progress.isBookmarked(widget.surah.number, widget.ayah.number);
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);
    final n = widget.ayah.number;
    final sn = widget.surah.number;
    return Container(
      decoration: BoxDecoration(
        color: playing ? scheme.secondaryContainer.withValues(alpha: 0.35) : null,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
            child: Text('$sn:$n', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          const Spacer(),
          if (s.audio.isAvailable(sn))
            IconButton(
              tooltip: t.playFromHere,
              visualDensity: VisualDensity.compact,
              icon: Icon(playing && p.playing ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                  color: scheme.primary),
              onPressed: () {
                if (playing && p.playing) {
                  p.pause();
                  return;
                }
                s.progress.addListened();
                s.player.playRange(sn, n, widget.surah.ayahs.length).catchError((Object _) {});
              },
            ),
          IconButton(
            tooltip: marked ? t.bookmarkRemove : t.bookmarkAdd,
            visualDensity: VisualDensity.compact,
            icon: Icon(marked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: marked ? scheme.secondary : scheme.onSurfaceVariant),
            onPressed: () => s.progress.toggleBookmark(sn, n),
          ),
          IconButton(
            tooltip: t.more,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
            onPressed: _actions,
          ),
        ]),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: ayahSpans(context, widget.ayah,
                style: quranStyle(context),
                playingWord: heardWord(p, sn, n),
                playingAyah: playing,
                wordTaps: _taps,
                onMarker: _actions),
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
        ),
      ]),
    );
  }
}
