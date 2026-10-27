import 'dart:isolate';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/quran/arabic.dart';
import '../../core/quran/quran_repo.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';

class _Entry {
  const _Entry(this.surah, this.ayah, this.text, this.normA, this.normB);
  final int surah;
  final int ayah;
  final String text;
  final String normA;
  final String normB;
}

/// Search by Arabic words, surah name, or a reference like 2:255.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static List<_Entry>? _index;
  final _query = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    if (_index == null) _build();
  }

  Future<void> _build() async {
    setState(() => _loading = true);
    final repo = AppScope.of(context).repo;
    final raw = <(int, int, String)>[];
    for (var s = 1; s <= 114; s++) {
      final surah = await repo.surah(s);
      for (final a in surah.ayahs) {
        raw.add((s, a.number, a.words.map((w) => w.mark == null ? w.text : '${w.text} ${w.mark}').join(' ')));
      }
    }
    final index = await Isolate.run(() => [
          for (final (s, a, text) in raw)
            _Entry(s, a, text, normalizeArabic(text), normalizeArabic(text, daggerAsAlif: true)),
        ]);
    _index = index;
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final repo = AppScope.of(context).repo;
    final q = _query.text.trim();
    final surahs = repo.surahsLoaded;
    final widgets = <Widget>[];
    if (q.isNotEmpty) {
      // A reference: 2:255 or 2 255
      final ref = RegExp(r'^(\d{1,3})\s*[:\s.]\s*(\d{1,3})$').firstMatch(q);
      if (ref != null) {
        final s = int.parse(ref.group(1)!), a = int.parse(ref.group(2)!);
        if (s >= 1 && s <= 114 && a >= 1 && a <= surahs[s - 1].ayahs) {
          widgets.add(ListTile(
            leading: const Icon(Icons.arrow_forward),
            title: Text('${surahs[s - 1].name} · ${t.ayahN(a)}', style: const TextStyle(fontSize: 20)),
            onTap: () => openRead(context, s, ayah: a),
          ));
        }
      }
      final nq = normalizeArabic(q);
      final lq = q.toLowerCase();
      for (final info in surahs) {
        if ((nq.isNotEmpty && normalizeArabic(info.name).contains(nq)) ||
            info.tname.toLowerCase().contains(lq) ||
            info.ename.toLowerCase().contains(lq) ||
            '${info.number}' == q) {
          widgets.add(ListTile(
            leading: CircleAvatar(child: Text('${info.number}')),
            title: Text(info.name, style: const TextStyle(fontFamily: quranFont, fontSize: 22)),
            subtitle: Text(surahSubtitle(context, info)),
            onTap: () => showSurahActions(context, info),
          ));
        }
      }
      final index = _index;
      if (index != null && nq.length >= 2) {
        var count = 0;
        for (final e in index) {
          if (!e.normA.contains(nq) && !e.normB.contains(nq)) continue;
          if (++count > 200) break;
          widgets.add(_AyahResult(entry: e, info: surahs[e.surah - 1]));
        }
      }
      if (widgets.isEmpty && !_loading) {
        widgets.add(Padding(padding: const EdgeInsets.all(32), child: Text(t.searchNoResults, textAlign: TextAlign.center)));
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: t.searchHint, border: InputBorder.none),
        ),
        actions: [
          if (q.isNotEmpty) IconButton(onPressed: _query.clear, icon: const Icon(Icons.clear), tooltip: t.cancel),
        ],
        bottom: _loading ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator()) : null,
      ),
      body: ListView(children: widgets),
    );
  }
}

class _AyahResult extends StatelessWidget {
  const _AyahResult({required this.entry, required this.info});
  final _Entry entry;
  final SurahInfo info;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListTile(
      title: Text(entry.text,
          textDirection: TextDirection.rtl,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: quranFont, fontSize: 20, height: 1.9)),
      subtitle: Text('${info.name} · ${t.ayahN(entry.ayah)}'),
      onTap: () => openRead(context, entry.surah, ayah: entry.ayah),
    );
  }
}
