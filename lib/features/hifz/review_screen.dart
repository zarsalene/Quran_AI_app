import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/align/session.dart';
import '../../core/progress/learning.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';
import '../teacher/recite_screen.dart';
import '../teacher/teacher_controller.dart';

/// Reviews due today: recite each ayah from memory. The grade sets the next
/// review date.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final _s = AppScope.of(context);
  late final List<AyahRef> _queue = [..._s.progress.dueRelearn(), ..._s.progress.dueReviews()]..sort(compareRef);
  int _i = 0;
  TeacherController? _c;
  int _good = 0;

  @override
  void initState() {
    super.initState();
    if (_queue.isNotEmpty) _open();
  }

  /// One teacher per surah: the model loads once for all its ayahs.
  Future<void> _open() async {
    final r = _queue[_i];
    final c = _c;
    if (c != null && c.layout.surah.number == r.surah) {
      await c.setRange(r.ayah, r.ayah, hidden: true, mode: TeacherMode.strict);
      setState(() {});
      return;
    }
    c?.dispose();
    setState(() => _c = null);
    final next = await createTeacher(_s, r.surah, from: r.ayah, to: r.ayah, hidden: true, mode: TeacherMode.strict);
    if (!mounted) {
      next.dispose();
      return;
    }
    next.onAyahDone = (_) => _s.progress.addRecited(1);
    setState(() => _c = next);
    await next.init();
  }

  void _gradeAndNext() {
    final c = _c!;
    final r = _queue[_i];
    final grade = gradeFor(perfect: c.perfect, mistakes: c.mistakes, hints: c.hints);
    if (grade >= 3) _good++;
    _s.progress.reviewAyah(r.surah, r.ayah, grade, surahs: _s.repo.surahsLoaded);
    celebrateNewBadges(context);
    setState(() => _i++);
    if (_i < _queue.length) _open();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_queue.isEmpty || _i >= _queue.length) {
      return Scaffold(
        appBar: AppBar(title: Text(t.reviewTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.task_alt, size: 96, color: Colors.green.shade600),
              const SizedBox(height: 12),
              Text(_queue.isEmpty ? t.reviewEmpty : t.reviewDone(_good, _queue.length),
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.ok)),
            ]),
          ),
        ),
      );
    }
    final r = _queue[_i];
    final c = _c;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_s.repo.surahsLoaded[r.surah - 1].name} · ${t.ayahN(r.ayah)}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: _i / _queue.length),
        ),
      ),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : TeacherView(
              key: ValueKey('${r.surah}:${r.ayah}'),
              controller: c,
              finishedAction: FilledButton.icon(
                onPressed: _gradeAndNext,
                icon: const Icon(Icons.arrow_forward),
                label: Text(t.next),
              ),
            ),
    );
  }
}
