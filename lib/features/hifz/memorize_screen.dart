import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/align/session.dart';
import '../../core/progress/learning.dart';
import '../../core/progress/progress_store.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';
import '../reader/ayah_widgets.dart';
import '../teacher/recite_screen.dart';
import '../teacher/teacher_controller.dart';

enum _Step { listen, read, memory, result, connect, done }

/// Memorize ayahs one by one: listen 3 times, read along, recite from memory.
/// Each ayah then gets a review date (spaced repetition).
class MemorizeScreen extends StatefulWidget {
  const MemorizeScreen({super.key, required this.surah, required this.from, required this.to});
  final int surah;
  final int from;
  final int to;

  @override
  State<MemorizeScreen> createState() => _MemorizeScreenState();
}

class _MemorizeScreenState extends State<MemorizeScreen> {
  late final _s = AppScope.of(context);
  TeacherController? _c;
  QSurah? _surah;
  late int _ayah = widget.from;
  _Step _step = _Step.listen;
  int _grade = 0;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await createTeacher(_s, widget.surah, from: widget.from, to: widget.from);
    final q = await _s.repo.surah(widget.surah);
    if (!mounted) {
      c.dispose();
      return;
    }
    c.onAyahDone = (_) => _s.progress.addRecited(1);
    setState(() {
      _c = c;
      _surah = q;
    });
    unawaited(c.init());
    _enterListen();
  }

  @override
  void dispose() {
    _s.player.stop();
    _c?.dispose();
    super.dispose();
  }

  Future<void> _enterListen() async {
    setState(() => _step = _Step.listen);
    _s.progress.setLast(ActivityKind.memorize, widget.surah, _ayah);
    if (!_s.audio.isAvailable(widget.surah)) return;
    setState(() => _listening = true);
    try {
      _s.progress.addListened();
      await _s.player.playAyahTimes(widget.surah, _ayah, 3);
    } catch (_) {
      // Audio is a help, never a blocker.
    }
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _enterRead() async {
    await _s.player.stop();
    await _c!.setRange(_ayah, _ayah, hidden: false, mode: TeacherMode.gentle);
    setState(() => _step = _Step.read);
  }

  Future<void> _enterMemory() async {
    await _c!.setRange(_ayah, _ayah, hidden: true, mode: TeacherMode.strict);
    setState(() => _step = _Step.memory);
  }

  void _finishMemory() {
    final c = _c!;
    _grade = gradeFor(perfect: c.perfect, mistakes: c.mistakes, hints: c.hints);
    _s.progress.reviewAyah(widget.surah, _ayah, _grade, surahs: _s.repo.surahsLoaded);
    setState(() => _step = _Step.result);
    celebrateNewBadges(context);
  }

  Future<void> _next() async {
    if (_ayah < widget.to) {
      _ayah++;
      await _enterListen();
    } else if (widget.to > widget.from) {
      await _c!.setRange(widget.from, widget.to, hidden: true, mode: TeacherMode.strict);
      setState(() => _step = _Step.connect);
    } else {
      setState(() => _step = _Step.done);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final info = _s.repo.surahsLoaded[widget.surah - 1];
    final c = _c;
    final surah = _surah;
    return Scaffold(
      appBar: AppBar(
        title: Text(info.name, style: const TextStyle(fontFamily: quranFont, fontSize: 24)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _Steps(step: _step, label: rangeLabel(t, _ayah, _ayah), count: '${_ayah - widget.from + 1}/${widget.to - widget.from + 1}'),
        ),
      ),
      body: c == null || surah == null
          ? const Center(child: CircularProgressIndicator())
          : switch (_step) {
              _Step.listen => _ListenStep(
                  surah: surah,
                  ayah: surah.ayahs[_ayah - 1],
                  playing: _listening,
                  onAgain: _enterListen,
                  onNext: _enterRead,
                ),
              _Step.read => TeacherView(
                  key: const ValueKey('read'),
                  controller: c,
                  finishedAction: FilledButton.icon(
                      onPressed: _enterMemory, icon: const Icon(Icons.arrow_forward), label: Text(t.next)),
                ),
              _Step.memory => TeacherView(
                  key: const ValueKey('memory'),
                  controller: c,
                  finishedAction: FilledButton.icon(
                      onPressed: _finishMemory, icon: const Icon(Icons.arrow_forward), label: Text(t.next)),
                ),
              _Step.result => _Result(
                  grade: _grade,
                  card: _s.progress.card(widget.surah, _ayah),
                  isLast: _ayah >= widget.to,
                  onRetry: _enterMemory,
                  onNext: _next,
                ),
              _Step.connect => TeacherView(
                  key: const ValueKey('connect'),
                  controller: c,
                  finishedAction: FilledButton.icon(
                      onPressed: () => setState(() => _step = _Step.done),
                      icon: const Icon(Icons.check),
                      label: Text(t.finish)),
                ),
              _Step.done => _Done(onClose: () => Navigator.of(context).pop()),
            },
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.step, required this.label, required this.count});
  final _Step step;
  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final current = switch (step) {
      _Step.listen => 0,
      _Step.read => 1,
      _Step.memory || _Step.result => 2,
      _Step.connect || _Step.done => 3,
    };
    Widget chip(int i, String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Chip(
            visualDensity: VisualDensity.compact,
            label: Text(text),
            backgroundColor: i == current ? scheme.primary : null,
            labelStyle: TextStyle(color: i == current ? scheme.onPrimary : null, fontSize: 12),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Text('$label  $count  ', style: Theme.of(context).textTheme.labelLarge),
          chip(0, t.stepListen),
          chip(1, t.stepRead),
          chip(2, t.stepMemory),
        ]),
      ),
    );
  }
}

class _ListenStep extends StatelessWidget {
  const _ListenStep({required this.surah, required this.ayah, required this.playing, required this.onAgain, required this.onNext});
  final QSurah surah;
  final QAyah ayah;
  final bool playing;
  final VoidCallback onAgain;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = AppScope.of(context);
    final hasAudio = s.audio.isAvailable(surah.number);
    return Column(children: [
      Expanded(
        child: ListenableBuilder(
          listenable: s.player,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(hasAudio ? t.stepListenHelp : t.stepListenNoAudio,
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              if (hasAudio && s.player.ayah == ayah.number)
                Text('${s.player.repeatNumber} / 3', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: ayahSpans(context, ayah,
                      style: quranStyle(context).copyWith(fontSize: quranStyle(context).fontSize! + 4),
                      playingWord: s.player.word,
                      playingAyah: isPlaying(s.player, surah.number, ayah.number)),
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      ),
      if (!hasAudio) AudioDownloadTile(surah: surah.number),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            if (hasAudio)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: playing ? null : onAgain,
                  icon: const Icon(Icons.replay),
                  label: Text(t.listenAgain),
                ),
              ),
            if (hasAudio) const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(onPressed: onNext, icon: const Icon(Icons.arrow_forward), label: Text(t.next)),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.grade, required this.card, required this.isLast, required this.onRetry, required this.onNext});
  final int grade;
  final MemoCard? card;
  final bool isLast;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ok = grade >= 3;
    final days = card?.interval ?? 1;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ok ? Icons.check_circle : Icons.refresh, size: 96, color: ok ? Colors.green.shade600 : Colors.orange.shade700),
          const SizedBox(height: 12),
          Text(ok ? t.memorizedOk : t.notYet, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          if (ok) Text(t.nextReview(days), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Wrap(spacing: 12, runSpacing: 8, alignment: WrapAlignment.center, children: [
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.replay), label: Text(t.tryAgain)),
            FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: Text(isLast ? t.finish : t.nextAyah),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(Icons.emoji_events, size: 120, color: Colors.amber.shade700),
          ),
          const SizedBox(height: 12),
          Text(t.allDone, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(t.allDoneBody, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(onPressed: onClose, child: Text(t.ok)),
        ]),
      ),
    );
  }
}
