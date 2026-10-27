import 'package:flutter/material.dart';

import '../../core/align/models.dart';
import '../../core/align/session.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import 'teacher_controller.dart';

const quranFont = 'AmiriQuran';

class ReciteScreen extends StatefulWidget {
  const ReciteScreen({super.key, required this.repo, required this.info});

  final QuranRepo repo;
  final SurahInfo info;

  @override
  State<ReciteScreen> createState() => _ReciteScreenState();
}

class _ReciteScreenState extends State<ReciteScreen> {
  TeacherController? _c;
  static bool _micExplained = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final surah = await widget.repo.surah(widget.info.number);
    final fatiha = await widget.repo.surah(1);
    final c = TeacherController(SurahLayout(surah, fatiha));
    setState(() => _c = c);
    await c.init();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Future<void> _onMic() async {
    final c = _c!;
    if (c.phase == TeacherPhase.listening) {
      await c.stopListening();
      return;
    }
    if (!await c.micAllowed()) {
      if (!_micExplained && mounted) {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).micDenied)));
        }
        return;
      }
    }
    await c.start();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = _c;
    return Scaffold(
      appBar: AppBar(title: Text(widget.info.name, style: const TextStyle(fontSize: 24))),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: c,
              builder: (context, _) => Column(
                children: [
                  if (c.phase != TeacherPhase.listening) _ModePicker(c),
                  Expanded(child: _SurahText(c)),
                  _BottomPanel(c, onMic: _onMic),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(t.disclaimer,
                        textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
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
            onSelectionChanged: (s) => c.setMode(s.first),
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
    final base = TextStyle(fontFamily: quranFont, fontSize: 28, height: 2.1, color: scheme.onSurface);
    final children = <Widget>[];
    if (layout.surah.basmala != null) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(layout.surah.basmala!, textAlign: TextAlign.center, style: base.copyWith(color: scheme.primary)),
      ));
    }
    var w = layout.basmalaWords;
    for (final ayah in layout.surah.ayahs) {
      final spans = <Widget>[];
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
    final color = _color(context, r, isStop);
    final text = word.mark == null ? word.text : '${word.text} ${word.mark}';
    return Semantics(
      label: r?.status.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: r == null || r.issues.isEmpty ? null : () => _showIssues(context, r),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: isStop
              ? BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8))
              : null,
          child: Text(text, textDirection: TextDirection.rtl, style: style.copyWith(color: color)),
        ),
      ),
    );
  }

  Color? _color(BuildContext context, WordResult? r, bool isStop) {
    if (isStop) return Colors.red.shade700;
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
  const _BottomPanel(this.c, {required this.onMic});
  final TeacherController c;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final String message;
    Widget? action;
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
        action = FilledButton.icon(
          onPressed: c.resume,
          icon: const Icon(Icons.replay),
          label: Text(t.repeatFromHere),
        );
      case TeacherPhase.finished:
        message = c.perfect
            ? t.perfect
            : c.mistakes > 0
                ? t.doneWithMistakes(c.mistakes)
                : t.doneNotPerfect;
        action = OutlinedButton.icon(onPressed: c.start, icon: const Icon(Icons.restart_alt), label: Text(t.again));
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
            ?action,
            if (canMic)
              SizedBox(
                width: 72,
                height: 72,
                child: FloatingActionButton.large(
                  heroTag: 'mic',
                  onPressed: onMic,
                  backgroundColor: listening ? Colors.red.shade600 : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  tooltip: listening ? t.listening : t.tapToStart,
                  child: Icon(listening ? Icons.stop : Icons.mic, size: 36),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
