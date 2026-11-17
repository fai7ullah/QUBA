import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/note_editor.dart';

/// All verse notes, in Quran order (surah, then ayah).
/// Tap a row to open the verse in the reader; edit and delete act on
/// the note itself.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key, required this.onOpenReader});
  final void Function(int surah, int ayah) onOpenReader;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;

    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              if (!repo.loaded) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TitleRow(title: tr('notes')),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          tr('loading'),
                          style: TextStyle(color: p.muted),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final notes = appState.notesSorted;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TitleRow(title: tr('notes')),
                    const SizedBox(height: 16),
                    if (notes.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            tr('no_notes'),
                            style:
                                TextStyle(fontSize: 15, color: p.muted),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 28),
                          itemCount: notes.length,
                          itemBuilder: (context, i) {
                            final (s, a, text) = notes[i];
                            // Defensive: notes can only be created from
                            // real verses, but skip stale ones quietly.
                            if (s < 1 || s > 114) {
                              return const SizedBox.shrink();
                            }
                            final surah = repo.surah(s);
                            if (a < 1 || a > surah.ayahCount) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                onTap: () => onOpenReader(s, a),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${surah.nameEnglish} $s:$a',
                                            style: TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w800,
                                              color: p.ink,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit_outlined),
                                          iconSize: 22,
                                          color: p.emerald,
                                          tooltip: tr('edit_note'),
                                          onPressed: () =>
                                              showNoteEditor(context, s, a),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons
                                              .delete_outline_rounded),
                                          iconSize: 22,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                          tooltip: tr('delete_note'),
                                          onPressed: () =>
                                              appState.deleteNote(s, a),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      repo.arabicText(s, a),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontFamily:
                                            repo.arabicFontFamily,
                                        fontSize: 20,
                                        height: 1.8,
                                        color: p.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        color: p.muted,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
