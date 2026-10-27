import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app_scope.dart';
import '../../core/align/models.dart';
import '../../core/align/session.dart';
import '../../core/progress/progress_store.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';
import 'teacher_controller.dart';

/// Recite an ayah range; the teacher checks each word.
class ReciteScreen extends StatefulWidget {
  const ReciteScreen({super.key, required this.surah, required this.from, required this.to});

  final int surah;
  final int from;
  final int to;

  @override
  State<ReciteScreen> createState() => _ReciteScreenState();
}

class _ReciteScreenState extends State<ReciteScreen> {
  TeacherController? _c;
  late final _services = AppScope.of(context);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await createTeacher(_services, widget.surah, from: widget.from, to: widget.to);
    if (!mounted) {
      c.dispose();
      return;
    }
    c.onAyahDone = (a) {
      _services.progress.addRecited(1);
      final next = a < c.layout.ayahCount ? a + 1 : a;
      _services.progress.setLast(ActivityKind.recite, widget.surah, next);
    };
    _services.progress.setLast(ActivityKind.recite, widget.surah, widget.from);
    setState(() => _c = c);
    await c.init();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final info = _services.repo.surahsLoaded[widget.surah - 1];
    final c = _c;
    return Scaffold(
      appBar: AppBar(
        title: Text(info.name, style: const TextStyle(fontFamily: quranFont, fontSize: 24)),
        actions: [
          if (c != null)
            ListenableBuilder(
              listenable: c,
              builder: (context, _) => IconButton(
                tooltip: t.memoryMode,
                isSelected: c.hidden,
                icon: const Icon(Icons.visibility),
                selectedIcon: const Icon(Icons.visibility_off),
                onPressed: c.phase == TeacherPhase.listening ? null : () => c.setRange(c.fromAyah, c.toAyah, hidden: !c.hidden),
              ),
            ),
        ],
      ),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : TeacherView(controller: c, showModePicker: true, onFinished: () => celebrateNewBadges(context)),
    );
  }
}

/// Loads the surah and builds a teacher for ayahs [from]..[to].
Future<TeacherController> createTeacher(AppServices s, int surah,
    {required int from, required int to, bool hidden = false, TeacherMode? mode}) async {
  final q = await s.repo.surah(surah);
  final fatiha = await s.repo.surah(1);
  return TeacherController(SurahLayout(q, fatiha),
      fromAyah: from, toAyah: to, hidden: hidden, mode: mode ?? s.settings.teacherMode);
}

bool _micExplained = false;

/// Explains the mic once, asks for it, then starts listening.
Future<void> startListening(BuildContext context, TeacherController c) async {
  if (c.phase == TeacherPhase.listening) {
    await c.stopListening();
    return;
  }
  AppScope.of(context).player.stop();
  if (!await c.micAllowed()) {
    if (!_micExplained && context.mounted) {
      final t = AppLocalizations.of(context);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.mic),
          title: Text(t.micTitle),
          content: Text(t.micBody),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.micContinue))],
        ),
      );
      if (ok != true) return;
      _micExplained = true;
    }
    if (!await c.requestMic()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).micDenied)));
      }
      return;
    }
  }
  if (c.phase == TeacherPhase.finished || c.phase == TeacherPhase.ready) await c.start();
}

/// The teacher on screen: the text, word colors, and the controls.
class TeacherView extends StatefulWidget {
  const TeacherView({
    super.key,
    required this.controller,
    this.showModePicker = false,
    this.onFinished,
    this.finishedAction,
  });

  final TeacherController controller;
  final bool showModePicker;
  final VoidCallback? onFinished;

  /// Replaces "Start again" when the range is finished (memorization: Next).
  final Widget? finishedAction;

  @override
  State<TeacherView> createState() => _TeacherViewState();
}

class _TeacherViewState extends State<TeacherView> {
  TeacherPhase? _lastPhase;
  late final _services = AppScope.of(context);

  TeacherController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_onChange);
  }

  @override
  void didUpdateWidget(TeacherView old) {
    super.didUpdateWidget(old);
    if (old.controller != c) {
      old.controller.removeListener(_onChange);
      c.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    WakelockPlus.disable();
    _services.player.stop();
    super.dispose();
  }

  void _onChange() {
    final phase = c.phase;
    if (phase == _lastPhase) return;
    _lastPhase = phase;
    // Keep the screen on while listening.
    phase == TeacherPhase.listening ? WakelockPlus.enable() : WakelockPlus.disable();
    if (phase == TeacherPhase.stopped) unawaited(playStopWord());
    if (phase == TeacherPhase.finished) widget.onFinished?.call();
  }

  bool get _canPlay => _services.audio.isAvailable(c.layout.surah.number);

  /// The model answer: the reciter says the word the reader got wrong.
  Future<void> playStopWord() async {
    final w = c.stopWord;
    if (w == null || !_canPlay) return;
    final inAyah = c.layout.wordInAyah(w);
    if (inAyah < 0) return;
    try {
      await _services.player.playWord(c.layout.surah.number, c.layout.wordAyah[w], inAyah);
    } catch (_) {
      // Audio is a help, never a blocker.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([c, _services.settings]),
      builder: (context, _) => Column(
        children: [
          if (widget.showModePicker && c.phase != TeacherPhase.listening) _ModePicker(c),
          Expanded(child: _SurahText(c)),
          _BottomPanel(
            c,
            onMic: () => startListening(context, c),
            onListenWord: _canPlay ? playStopWord : null,
            finishedAction: widget.finishedAction,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(t.disclaimer, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker(this.c);
  final TeacherController c;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          SegmentedButton<TeacherMode>(
            segments: [
              ButtonSegment(value: TeacherMode.strict, label: Text(t.modeStrict), icon: const Icon(Icons.pan_tool)),
              ButtonSegment(value: TeacherMode.gentle, label: Text(t.modeGentle), icon: const Icon(Icons.edit_note)),
            ],
            selected: {c.mode},
            onSelectionChanged: (s) {
              c.setMode(s.first);
              AppScope.of(context).settings.teacherMode = s.first;
            },
          ),
          const SizedBox(height: 4),
          Text(c.mode == TeacherMode.strict ? t.modeStrictHelp : t.modeGentleHelp,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SurahText extends StatelessWidget {
  const _SurahText(this.c);
  final TeacherController c;

  @override
  Widget build(BuildContext context) {
    final layout = c.layout;
    final scheme = Theme.of(context).colorScheme;
    final size = AppScope.of(context).settings.quranFontSize;
    final base = TextStyle(fontFamily: quranFont, fontSize: size, height: 2.0, color: scheme.onSurface);
    final children = <Widget>[];
    if (c.hidden) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(AppLocalizations.of(context).hiddenHelp,
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.primary)),
      ));
    }
    if (c.showsBasmala && layout.surah.basmala != null) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(layout.surah.basmala!, textAlign: TextAlign.center, style: base.copyWith(color: scheme.primary)),
      ));
    }
    for (var a = c.fromAyah; a <= c.toAyah; a++) {
      final ayah = layout.surah.ayahs[a - 1];
      final spans = <Widget>[];
      var w = layout.ayahFirstWord(a);
      for (final word in ayah.words) {
        spans.add(_Word(word: word, index: w, c: c, style: base));
        w++;
      }
      spans.add(_AyahNumber(ayah.number));
      children.add(Wrap(
        textDirection: TextDirection.rtl,
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: spans,
      ));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _Word extends StatelessWidget {
  const _Word({required this.word, required this.index, required this.c, required this.style});

  final QWord word;
  final int index;
  final TeacherController c;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final r = c.results[index];
    final isStop = c.stopWord == index;
    final visible = c.isVisible(index);
    final scheme = Theme.of(context).colorScheme;
    final color = visible ? _color(r, isStop) : Colors.transparent;
    final text = word.mark == null ? word.text : '${word.text} ${word.mark}';
    return Semantics(
      label: visible ? r?.status.name : AppLocalizations.of(context).hiddenWord,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: r == null || r.issues.isEmpty || !visible ? null : () => _showIssues(context, r),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: isStop
              ? BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8))
              : !visible
                  ? BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8))
                  : null,
          child: Text(text, textDirection: TextDirection.rtl, style: style.copyWith(color: color)),
        ),
      ),
    );
  }

  Color? _color(WordResult? r, bool isStop) {
    if (isStop) return Colors.red.shade700;
    if (c.peeked.contains(index) && (r == null || r.status == WordStatus.pending)) return Colors.blueGrey;
    if (r == null) return null;
    return switch (r.status) {
      WordStatus.pending => null,
      WordStatus.correct => r.hasMedium ? Colors.orange.shade800 : Colors.green.shade700,
      WordStatus.unsure => Colors.blueGrey,
      WordStatus.wrong || WordStatus.skipped || WordStatus.jumped => Colors.red.shade700,
    };
  }

  void _showIssues(BuildContext context, WordResult r) {
    final t = AppLocalizations.of(context);
    final labels = <String>{
      for (final i in r.issues) i.unsure ? t.unsure : issueLabel(t, i.type),
    };
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(word.text, style: style.copyWith(fontSize: 40)),
            const SizedBox(height: 12),
            for (final l in labels) Text(l, style: Theme.of(context).textTheme.titleMedium),
          ]),
        ),
      ),
    );
  }
}

String issueLabel(AppLocalizations t, IssueType type) => switch (type) {
      IssueType.missingWord => t.issueMissingWord,
      IssueType.wrongLetter => t.issueWrongLetter,
      IssueType.missingLetter => t.issueMissingLetter,
      IssueType.extraLetter => t.issueExtraLetter,
      IssueType.extraWord => t.issueExtraWord,
      IssueType.harakat => t.issueHarakat,
      IssueType.longVowel => t.issueLongVowel,
      IssueType.shadda => t.issueShadda,
      IssueType.maddLength || IssueType.ghunna || IssueType.ikhfa || IssueType.qalqala || IssueType.otherTajweed =>
        t.issueTajweed,
    };

class _AyahNumber extends StatelessWidget {
  const _AyahNumber(this.number);
  final int number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.primary, width: 1.5)),
      child: Text('$number', style: TextStyle(fontSize: 13, color: scheme.primary)),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel(this.c, {required this.onMic, this.onListenWord, this.finishedAction});
  final TeacherController c;
  final VoidCallback onMic;
  final VoidCallback? onListenWord;
  final Widget? finishedAction;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final String message;
    final actions = <Widget>[];
    switch (c.phase) {
      case TeacherPhase.loading:
        message = t.teacherLoading;
      case TeacherPhase.error:
        message = t.errorStart(c.error ?? '');
      case TeacherPhase.ready:
        message = t.tapToStart;
      case TeacherPhase.listening:
        message = c.noisy ? t.tooNoisy : t.listening;
      case TeacherPhase.stopped:
        final issue = c.stopIssue;
        message = c.stopWasJump
            ? t.jumpedBody
            : '${t.stopTitle}: ${issue == null ? '' : issueLabel(t, issue.type)}. ${t.stopBody}';
        if (onListenWord != null) {
          actions.add(OutlinedButton.icon(onPressed: onListenWord, icon: const Icon(Icons.volume_up), label: Text(t.listenWord)));
        }
        actions.add(FilledButton.icon(
          onPressed: () async {
            // The mic must not hear the reciter.
            await AppScope.of(context).player.stop();
            await c.resume();
          },
          icon: const Icon(Icons.replay),
          label: Text(t.repeatFromHere),
        ));
      case TeacherPhase.finished:
        message = c.perfect
            ? t.perfect
            : c.mistakes > 0
                ? t.doneWithMistakes(c.mistakes)
                : t.doneNotPerfect;
        actions.add(finishedAction ??
            OutlinedButton.icon(onPressed: c.start, icon: const Icon(Icons.restart_alt), label: Text(t.again)));
    }
    final listening = c.phase == TeacherPhase.listening;
    final canMic = c.phase == TeacherPhase.ready || listening;
    return Material(
      elevation: 3,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: c.phase == TeacherPhase.finished && c.perfect
                    ? theme.textTheme.headlineSmall?.copyWith(color: Colors.green.shade700)
                    : theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (actions.isNotEmpty) Wrap(spacing: 12, runSpacing: 8, alignment: WrapAlignment.center, children: actions),
            if (canMic)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (c.hidden)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 24),
                    child: OutlinedButton.icon(onPressed: c.peek, icon: const Icon(Icons.lightbulb_outline), label: Text(t.hint)),
                  ),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: FloatingActionButton.large(
                    heroTag: null,
                    onPressed: onMic,
                    backgroundColor: listening ? Colors.red.shade600 : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    tooltip: listening ? t.listening : t.tapToStart,
                    child: Icon(listening ? Icons.stop : Icons.mic, size: 36),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
