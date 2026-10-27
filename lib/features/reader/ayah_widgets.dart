import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/audio/recitation_player.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';

/// Builds the spans of one ayah: its words (verbatim) and its end marker.
/// The word the reciter is on is highlighted.
List<InlineSpan> ayahSpans(
  BuildContext context,
  QAyah ayah, {
  required TextStyle style,
  int? playingWord,
  bool playingAyah = false,
  GestureRecognizer? recognizer,
}) {
  final scheme = Theme.of(context).colorScheme;
  final spans = <InlineSpan>[];
  for (var i = 0; i < ayah.words.length; i++) {
    final w = ayah.words[i];
    final active = playingAyah && playingWord == i;
    spans.add(TextSpan(
      text: w.mark == null ? w.text : '${w.text} ${w.mark}',
      recognizer: recognizer,
      style: active
          ? style.copyWith(color: scheme.onPrimary, backgroundColor: scheme.primary)
          : playingAyah
              ? style.copyWith(color: scheme.primary)
              : style,
    ));
    spans.add(TextSpan(text: ' ', style: style));
  }
  spans.add(TextSpan(
    text: ayahMarker(ayah.number),
    recognizer: recognizer,
    style: style.copyWith(color: scheme.primary, fontSize: (style.fontSize ?? 28) * 0.85),
  ));
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${s.repo.surahsLoaded[surah - 1].name} · ${t.ayahN(ayah)}',
              style: Theme.of(ctx).textTheme.titleMedium),
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
            leading: const Icon(Icons.psychology_alt),
            title: Text(t.memorizeAyah),
            onTap: () => act(() => openMemorize(context, surah, ayah, ayah)),
          ),
          ListTile(
            leading: Icon(marked ? Icons.bookmark_remove : Icons.bookmark_add),
            title: Text(marked ? t.bookmarkRemove : t.bookmarkAdd),
            onTap: () => act(() => s.progress.toggleBookmark(surah, ayah)),
          ),
        ]),
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
    return Material(
      elevation: 3,
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([s.player, s.audio]),
          builder: (context, _) {
            if (!s.audio.isAvailable(surah)) return AudioDownloadTile(surah: surah);
            final p = s.player;
            final mine = p.surah == surah && p.isRangeActive;
            final playing = mine && p.playing;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(children: [
                IconButton.filled(
                  iconSize: 36,
                  tooltip: playing ? t.pause : t.play,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mine && p.ayah != null
                        ? '${t.ayahN(p.ayah!)}${p.repeatEach > 1 ? '  (${p.repeatNumber}/${p.repeatEach})' : ''}'
                        : t.reciterName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => p.setRepeat(_repeats[(_repeats.indexOf(p.repeatEach) + 1) % _repeats.length]),
                  child: Tooltip(message: t.repeatEachTooltip, child: Text('×${p.repeatEach}')),
                ),
                IconButton(
                  tooltip: t.loop,
                  isSelected: p.loopRange,
                  icon: const Icon(Icons.repeat),
                  selectedIcon: Icon(Icons.repeat_on, color: scheme.primary),
                  onPressed: () => p.setLoop(!p.loopRange),
                ),
                TextButton(
                  onPressed: () => p.setSpeed(_speeds[(_speeds.indexOf(p.speed) + 1) % _speeds.length]),
                  child: Tooltip(message: t.speed, child: Text('${p.speed}×')),
                ),
                if (mine)
                  IconButton(tooltip: t.stop, icon: const Icon(Icons.stop), onPressed: p.stop),
              ]),
            );
          },
        ),
      ),
    );
  }
}

/// Wraps [RecitationPlayer] state for one ayah, so only playing ayahs repaint.
bool isPlaying(RecitationPlayer p, int surah, int ayah) => p.isRangeActive && p.surah == surah && p.ayah == ayah;
