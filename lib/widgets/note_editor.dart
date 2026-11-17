import 'package:flutter/material.dart';

import '../app_state.dart';
import '../i18n.dart';
import '../theme.dart';

/// Dialog to add, edit or delete the free-text note on one verse.
///
/// Called from the reader's note button and from [NotesScreen].
/// The existing note (if any) is pre-filled; saving empty text deletes
/// the note, matching [AppState.setNote].
Future<void> showNoteEditor(BuildContext context, int surah, int ayah) async {
  final existing = appState.noteFor(surah, ayah);
  final hasNote = existing.isNotEmpty;
  final controller = TextEditingController(text: existing);
  final p = QubaPalette.of(context);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: p.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(hasNote ? tr('edit_note') : tr('add_note')),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: tr('note_hint'),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        if (hasNote)
          TextButton(
            onPressed: () {
              appState.deleteNote(surah, ayah);
              Navigator.of(context).pop();
            },
            child: Text(
              tr('delete_note'),
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel')),
        ),
        TextButton(
          onPressed: () {
            appState.setNote(surah, ayah, controller.text);
            Navigator.of(context).pop();
          },
          child: Text(tr('save')),
        ),
      ],
    ),
  );
  controller.dispose();
}
