import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/align/session.dart';
import '../../core/audio/audio_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../common.dart';
import '../home/home_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = AppScope.of(context);
    final st = s.settings;
    return Scaffold(
      appBar: AppBar(title: Text(t.navSettings)),
      body: ListenableBuilder(
        listenable: Listenable.merge([st, s.audio]),
        builder: (context, _) => ListView(children: [
          _Section(t.settingsLanguage),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 8, children: [
              for (final (code, label) in [('', t.languageSystem), ('ar', 'العربية'), ('en', 'English'), ('fr', 'Français')])
                ChoiceChip(
                  label: Text(label),
                  selected: (st.locale?.languageCode ?? '') == code,
                  onSelected: (_) => st.locale = code.isEmpty ? null : Locale(code),
                ),
            ]),
          ),
          _Section(t.settingsTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(t.themeSystem), icon: const Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text(t.themeLight), icon: const Icon(Icons.light_mode)),
                ButtonSegment(value: ThemeMode.dark, label: Text(t.themeDark), icon: const Icon(Icons.dark_mode)),
              ],
              selected: {st.themeMode},
              onSelectionChanged: (v) => st.themeMode = v.first,
            ),
          ),
          _Section(t.settingsFont),
          Slider(
            value: st.quranFontSize,
            min: 20,
            max: 44,
            divisions: 12,
            label: st.quranFontSize.round().toString(),
            onChanged: (v) => st.quranFontSize = v,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // Preview: Al-Fatiha 1:1 from the verified data, never typed here.
            child: FutureBuilder(
              future: s.text(1),
              builder: (context, snap) => Text(
                snap.data?.ayahs.first.words.map((w) => w.text).join(' ') ?? '',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: quranFont, fontSize: st.quranFontSize, height: 2),
              ),
            ),
          ),
          _Section(t.settingsTeacher),
          RadioGroup<TeacherMode>(
            groupValue: st.teacherMode,
            onChanged: (v) => st.teacherMode = v!,
            child: Column(children: [
              RadioListTile(value: TeacherMode.strict, title: Text(t.modeStrict), subtitle: Text(t.modeStrictHelp)),
              RadioListTile(value: TeacherMode.gentle, title: Text(t.modeGentle), subtitle: Text(t.modeGentleHelp)),
            ]),
          ),
          _Section(t.settingsGoal),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 8, children: [
              for (final n in [3, 5, 10, 20])
                ChoiceChip(label: Text(t.goalAyahs(n)), selected: st.dailyGoal == n, onSelected: (_) => st.dailyGoal = n),
            ]),
          ),
          _Section(t.settingsAudio),
          RadioGroup<Reciter>(
            groupValue: st.reciter,
            onChanged: (v) => st.reciter = v!,
            child: Column(children: [
              RadioListTile(value: Reciter.husaryMuallim, title: Text(t.reciterHusary), subtitle: Text(t.reciterHusaryHelp)),
              RadioListTile(value: Reciter.alafasy, title: Text(t.reciterName), subtitle: Text(t.reciterAlafasyHelp)),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.sd_storage_outlined),
            title: Text(t.audioOnPhone((s.audio.downloadedBytes() / 1e6).toStringAsFixed(0))),
            subtitle: s.audio.reciter.bundled ? Text(t.bundledNote) : null,
          ),
          if (s.audio.missingBytes() > 0)
            ListTile(
              leading: s.audio.downloadingAll
                  ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator())
                  : const Icon(Icons.download),
              title: Text(s.audio.downloadingAll
                  ? t.downloadingAll(s.audio.downloading.keys.firstOrNull ?? 0)
                  : t.downloadAll((s.audio.missingBytes() / 1e6).toStringAsFixed(0))),
              subtitle: Text(t.downloadAllHelp),
              trailing: s.audio.downloadingAll ? TextButton(onPressed: s.audio.cancelAll, child: Text(t.stop)) : null,
              onTap: s.audio.downloadingAll ? null : s.audio.downloadAll,
            ),
          if (s.audio.downloadedBytes() > 0)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(t.deleteDownloads),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: Text(t.confirmDelete),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
                    ],
                  ),
                );
                if (ok == true) await s.audio.deleteDownloads();
              },
            ),
          _Section(t.settingsAbout),
          ListTile(leading: const Icon(Icons.lock_outline), title: Text(t.privacy)),
          ListTile(leading: const Icon(Icons.info_outline), title: Text(t.disclaimer)),
          ListTile(
            leading: const Icon(Icons.library_books_outlined),
            title: Text(t.sourcesTitle),
            subtitle: Text(t.sourcesBody),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(t.licenses),
            onTap: () => showLicensePage(context: context, applicationName: t.appTitle, applicationVersion: appVersion),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
