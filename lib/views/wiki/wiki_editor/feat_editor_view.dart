import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/configs/colours.dart';

class AddFeatPage extends StatefulWidget {
  final Future<void> Function(FeatData) onSave;
  final FeatData? existingFeat;

  const AddFeatPage({super.key, required this.onSave, this.existingFeat});

  @override
  AddFeatPageState createState() => AddFeatPageState();
}

class AddFeatPageState extends State<AddFeatPage> {
  final _nameController = TextEditingController();
  final _prerequisiteController = TextEditingController();
  final _textController = TextEditingController();
  final _modifierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingFeat != null) {
      _loadExistingFeat();
    }
  }

  void _loadExistingFeat() {
    final feat = widget.existingFeat!;
    _nameController.text = feat.name;
    _prerequisiteController.text = feat.prerequisite ?? '';
    _textController.text = feat.text;
    _modifierController.text = feat.modifier ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prerequisiteController.dispose();
    _textController.dispose();
    _modifierController.dispose();
    super.dispose();
  }

  Future<void> _saveFeat() async {
    final featData = FeatData(
      name: _nameController.text.trim(),
      prerequisite: _prerequisiteController.text.trim().isEmpty
          ? null
          : _prerequisiteController.text.trim(),
      text: _textController.text.trim(),
      modifier: _modifierController.text.trim().isEmpty
          ? null
          : _modifierController.text.trim(),
    );

    await widget.onSave(featData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addTalent),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveFeat,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.name,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _prerequisiteController,
                      decoration: InputDecoration(
                        labelText: '${loc.requirement} (optional)',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: loc.description,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _modifierController,
                      decoration: InputDecoration(
                        labelText: '${loc.modifier} (optional)',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
