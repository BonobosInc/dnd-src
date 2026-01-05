import 'package:flutter/material.dart';
import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/views/canvas_note_page.dart';

class CanvasNotesListPage extends StatefulWidget {
  final ProfileManager profileManager;

  const CanvasNotesListPage({
    super.key,
    required this.profileManager,
  });

  @override
  CanvasNotesListPageState createState() => CanvasNotesListPageState();
}

class CanvasNotesListPageState extends State<CanvasNotesListPage> {
  List<Map<String, dynamic>> _canvasNotes = [];

  @override
  void initState() {
    super.initState();
    _loadCanvasNotes();
  }

  Future<void> _loadCanvasNotes() async {
    final notes = await widget.profileManager.getCanvasNotes();
    setState(() {
      _canvasNotes = List.from(notes);
    });
  }

  void _createNewCanvasNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CanvasNotePage(
          profileManager: widget.profileManager,
        ),
      ),
    );

    if (result != null) {
      final String title = result['title'] ?? 'Canvas Note';

      await widget.profileManager.createCanvasNote(
        title: title,
        canvasData: result['canvasData'],
        textNotes: result['textNotes'],
      );
      _loadCanvasNotes();
    }
  }

  void _editCanvasNote(Map<String, dynamic> note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CanvasNotePage(
          profileManager: widget.profileManager,
          initialData: note['canvas_data'],
          initialTextNotes: note['text_notes'],
          initialTitle: note['title'],
        ),
      ),
    );

    if (result != null) {
      await widget.profileManager.updateCanvasNote(
        id: note['ID'],
        title: result['title'],
        canvasData: result['canvasData'],
        textNotes: result['textNotes'],
      );
      _loadCanvasNotes();
    }
  }

  void _deleteCanvasNote(int index) {
    final noteToDelete = _canvasNotes[index];
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.confirmdelete),
          content: Text(loc.deleteCanvasNoteConfirm),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () async {
                await widget.profileManager
                    .deleteCanvasNote(noteToDelete['ID']);
                setState(() {
                  _canvasNotes.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: Text(loc.delete),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.canvasNotes),
        backgroundColor: AppColors.appBarColor,
      ),
      body: _canvasNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.draw,
                    size: 80,
                    color: AppColors.textColorLight.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.noCanvasNotesYet,
                    style: TextStyle(
                      color: AppColors.textColorLight.withOpacity(0.5),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.tapPlusToCreate,
                    style: TextStyle(
                      color: AppColors.textColorLight.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _canvasNotes.length,
              itemBuilder: (context, index) {
                final note = _canvasNotes[index];
                return Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  color: AppColors.cardColor,
                  child: ListTile(
                    leading: Icon(Icons.draw, color: AppColors.accentCyan),
                    title: Text(
                      note['title'] ?? 'Canvas Note ${index + 1}',
                      style: TextStyle(color: AppColors.textColorLight),
                    ),
                    subtitle: note['textNotes'] != null &&
                            note['textNotes'].toString().isNotEmpty
                        ? Text(
                            note['textNotes'].toString().length > 50
                                ? '${note['textNotes'].toString().substring(0, 50)}...'
                                : note['textNotes'].toString(),
                            style: TextStyle(
                              color: AppColors.textColorLight.withOpacity(0.7),
                            ),
                          )
                        : null,
                    onTap: () => _editCanvasNote(note),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: AppColors.warningColor),
                      onPressed: () => _deleteCanvasNote(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCanvasNote,
        backgroundColor: AppColors.accentCyan,
        child: const Icon(Icons.add),
      ),
    );
  }
}
