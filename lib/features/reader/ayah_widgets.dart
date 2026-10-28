import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/audio/audio_catalog.dart';
import '../../core/audio/recitation_player.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';

/// Builds the spans of one ayah: its words (verbatim) and its end marker.
/// The word being heard is highlighted. [wordTaps] holds one recognizer per
/// word (tap a word to hear it); [onMarker] runs when the ayah medallion is
/// tapped.
List<InlineSpan> ayahSpans(
  BuildContext context,
  QAyah ayah, {
  required TextStyle style,
  int? playingWord,
  bool playingAyah = false,
  List<GestureRecognizer>? wordTaps,
  VoidCallback? onMarker,
}) {
  final scheme = Theme.of(context).colorScheme;
  final spans = <InlineSpan>[];
  for (var i = 0; i < ayah.words.length; i++) {
    final w = ayah.words[i];
    final active = playingWord == i;
    spans.add(
      TextSpan(
        text: w.mark == null ? w.text : '${w.text} ${w.mark}',
        recognizer: wordTaps?[i],
        style: active
            ? style.copyWith(color: scheme.onSecondaryContainer, backgroundColor: scheme.secondaryContainer)
            : playingAyah
            ? style.copyWith(color: scheme.primary)
            : style,
      ),
    );
    spans.add(TextSpan(text: ' ', style: style));
  }
  spans.add(
    WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: onMarker,
        child: AyahEndMarker(number: ayah.number, size: (style.fontSize ?? 28) * 0.95, active: playingAyah),
      ),
    ),
  );
  spans.add(TextSpan(text: ' ', style: style));
  return spans;
}

TextStyle quranStyle(BuildContext context) {
  final size = AppScope.of(context).settings.quranFontSize;
  return TextStyle(fontFamily: quranFont, fontSize: size, height: 2.0, color: Theme.of(context).colorScheme.onSurface);
}

/// Actions on one ayah: play, repeat, recite, memorize, bookmark.
Future<void> showAyahActions(BuildContext context, int surah, int ayah, {required int surahAyahs}) {
  final s = AppScope.of(context);
  final t = AppLocalizations.of(context);
  final marked = s.progress.isBookmarked(surah, ayah);
  final hasAudio = s.audio.isAvailable(surah);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      void act(VoidCallback f) {
        Navigator.pop(ctx);
        f();
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${s.repo.surahsLoaded[surah - 1].name} · ${t.ayahN(ayah)}', style: Theme.of(ctx).textTheme.titleMedium),
            if (hasAudio) ...[
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: Text(t.playFromHere),
                onTap: () => act(() {
                  s.player.setLoop(false);
                  s.progress.addListened();
                  s.player.playRange(surah, ayah, surahAyahs).catchError((Object _) {});
                }),
              ),
              ListTile(
                leading: const Icon(Icons.repeat_one),
                title: Text(t.repeatAyah),
                onTap: () => act(() {
                  s.player.setLoop(true);
                  s.progress.addListened();
                  s.player.playRange(surah, ayah, ayah).catchError((Object _) {});
                }),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.mic),
              title: Text(t.reciteFromHere),
              onTap: () => act(() => openRecite(context, surah, ayah, surahAyahs)),
            ),
            ListTile(
              leading: const Icon(Icons.school_rounded),
              title: Text(t.memorizeAyah),
              onTap: () => act(() => openMemorize(context, surah, ayah, ayah)),
            ),
            ListTile(
              leading: Icon(marked ? Icons.bookmark_remove : Icons.bookmark_add),
              title: Text(marked ? t.bookmarkRemove : t.bookmarkAdd),
              onTap: () => act(() => s.progress.toggleBookmark(surah, ayah)),
            ),
          ],
        ),
      );
    },
  );
}

/// Play controls: play/pause, repeat count, loop, speed. Shows a download
/// prompt when the surah audio is not on the phone.
class AudioBar extends StatelessWidget {
  const AudioBar({super.key, required this.surah, required this.ayahs, required this.startAyah});
  final int surah;
  final int ayahs;

  /// Where "play" starts when nothing is playing.
  final int Function() startAyah;

  static const _repeats = [1, 3, 5, 10];
  static const _speeds = [0.75, 1.0, 1.25];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: Material(
          color: scheme.surfaceContainer,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListenableBuilder(
            listenable: Listenable.merge([s.player, s.audio]),
            builder: (context, _) {
              if (!s.audio.isAvailable(surah)) return AudioDownloadTile(surah: surah);
              final p = s.player;
              final mine = p.surah == surah && p.isRangeActive;
              final playing = mine && p.playing;
              Widget pill(Widget child, String tip, VoidCallback onTap, {bool on = false}) => Tooltip(
                message: tip,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: Container(
                    // No alignment here: it would stretch the dock to the full screen height.
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 40, maxHeight: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: on ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: DefaultTextStyle.merge(
                        style: TextStyle(fontWeight: FontWeight.w700, color: on ? scheme.onSecondaryContainer : scheme.onSurface),
                        child: IconTheme.merge(
                          data: IconThemeData(size: 20, color: on ? scheme.onSecondaryContainer : scheme.onSurface),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 52,
                      child: IconButton.filled(
                        iconSize: 32,
                        tooltip: playing ? t.pause : t.play,
                        icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        onPressed: () async {
                          if (playing) {
                            await p.pause();
                          } else if (mine) {
                            await p.resume();
                          } else {
                            s.progress.addListened();
                            try {
                              await p.playRange(surah, startAyah(), ayahs);
                            } on AudioNotAvailable {
                              // The download tile shows instead.
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mine && p.ayah != null ? t.ayahN(p.ayah!) : reciterLabel(t, s.audio.reciter),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (mine && p.repeatEach > 1)
                            Text(
                              '${p.repeatNumber}/${p.repeatEach}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                    pill(
                      Text('×${p.repeatEach}'),
                      t.repeatEachTooltip,
                      () => p.setRepeat(_repeats[(_repeats.indexOf(p.repeatEach) + 1) % _repeats.length]),
                      on: p.repeatEach > 1,
                    ),
                    const SizedBox(width: 6),
                    pill(const Icon(Icons.repeat_rounded), t.loop, () => p.setLoop(!p.loopRange), on: p.loopRange),
                    const SizedBox(width: 6),
                    pill(
                      Text('${p.speed}×'),
                      t.speed,
                      () => p.setSpeed(_speeds[(_speeds.indexOf(p.speed) + 1) % _speeds.length]),
                      on: p.speed != 1.0,
                    ),
                    if (mine) IconButton(tooltip: t.stop, icon: const Icon(Icons.stop_rounded), onPressed: p.stop),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Whether the reciter is on [ayah] of [surah] in an ayah range.
bool isPlaying(RecitationPlayer p, int surah, int ayah) => p.isRangeActive && p.surah == surah && p.ayah == ayah;

/// The word of [ayah] being heard (in a range or alone), or null.
int? heardWord(RecitationPlayer p, int surah, int ayah) =>
    (p.isRangeActive || p.wordPlaying) && p.surah == surah && p.ayah == ayah ? p.word : null;

/// One recognizer per word of [ayah]: a tap plays that word, read correctly
/// by the teaching reciter. The caller disposes them.
List<TapGestureRecognizer> wordRecognizers(BuildContext context, int surah, QAyah ayah) => [
  for (var i = 0; i < ayah.words.length; i++) TapGestureRecognizer()..onTap = () => hearWord(context, surah, ayah.number, i),
];

/// Plays one word from the clearest recording on the phone.
Future<void> hearWord(BuildContext context, int surah, int ayah, int word) async {
  final s = AppScope.of(context);
  final from = s.wordAudio(surah);
  if (from == null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).audioMissing)));
    return;
  }
  try {
    await s.player.playWord(surah, ayah, word, from: from);
  } catch (_) {
    // Audio is a help, never a blocker.
  }
}

String reciterLabel(AppLocalizations t, Reciter r) => switch (r) {
  Reciter.husaryMuallim => t.reciterHusaryShort,
  Reciter.alafasy => t.reciterName,
};

/// One ayah, centered: tap a word to hear it; the word being heard lights up.
class TappableAyah extends StatefulWidget {
  const TappableAyah({super.key, required this.surah, required this.ayah, required this.style});
  final int surah;
  final QAyah ayah;
  final TextStyle style;

  @override
  State<TappableAyah> createState() => _TappableAyahState();
}

class _TappableAyahState extends State<TappableAyah> {
  late List<TapGestureRecognizer> _taps = wordRecognizers(context, widget.surah, widget.ayah);

  @override
  void didUpdateWidget(TappableAyah old) {
    super.didUpdateWidget(old);
    if (old.ayah != widget.ayah || old.surah != widget.surah) {
      _dispose();
      _taps = wordRecognizers(context, widget.surah, widget.ayah);
    }
  }

  void _dispose() {
    for (final r in _taps) {
      r.dispose();
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).player;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) => Text.rich(
        TextSpan(
          children: ayahSpans(context, widget.ayah,
              style: widget.style,
              playingWord: heardWord(p, widget.surah, widget.ayah.number),
              playingAyah: isPlaying(p, widget.surah, widget.ayah.number),
              wordTaps: _taps),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      ),
    );
  }
}
