import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/configs/colours.dart';

class AddItemPage extends StatefulWidget {
  final Future<void> Function(ItemData) onSave;
  final ItemData? existingItem;

  const AddItemPage({super.key, required this.onSave, this.existingItem});

  @override
  AddItemPageState createState() => AddItemPageState();
}

class AddItemPageState extends State<AddItemPage> {
  // Type code to full name mapping
  static const Map<String, String> typeNames = {
    r'$': 'Currency',
    'A': 'Ammunition',
    'LA': 'Light Armor',
    'MA': 'Medium Armor',
    'HA': 'Heavy Armor',
    'M': 'Melee Weapon',
    'P': 'Potion',
    'R': 'Ranged Weapon',
    'RD': 'Rod',
    'RG': 'Ring',
    'SC': 'Scroll',
    'S': 'Shield',
    'W': 'Wondrous Item',
    'G': 'Adventuring Gear',
    'T': 'Tools',
    'AF': 'Artisan Focus',
    'TG': 'Trade Goods',
  };

  final _nameController = TextEditingController();
  String? _selectedTypeCode;
  final _weightController = TextEditingController();
  final _valueController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _loadExistingItem();
    }
  }

  void _loadExistingItem() {
    final item = widget.existingItem!;
    _nameController.text = item.name;
    _selectedTypeCode = item.type.isNotEmpty ? item.type : null;
    _weightController.text = item.weight;
    _valueController.text = item.value;
    _textController.text = item.text;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _valueController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    final item = ItemData(
      name: _nameController.text.trim(),
      type: _selectedTypeCode ?? '',
      weight: _weightController.text.trim(),
      value: _valueController.text.trim(),
      text: _textController.text.trim(),
    );

    await widget.onSave(item);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _getLocalizedTypeName(AppLocalizations loc, String typeCode) {
    switch (typeCode) {
      case r'$':
        return loc.itemTypeCurrency;
      case 'A':
        return loc.itemTypeAmmunition;
      case 'LA':
        return loc.itemTypeLightArmor;
      case 'MA':
        return loc.itemTypeMediumArmor;
      case 'HA':
        return loc.itemTypeHeavyArmor;
      case 'M':
        return loc.itemTypeMeleeWeapon;
      case 'P':
        return loc.itemTypePotion;
      case 'R':
        return loc.itemTypeRangedWeapon;
      case 'RD':
        return loc.itemTypeRod;
      case 'RG':
        return loc.itemTypeRing;
      case 'SC':
        return loc.itemTypeScroll;
      case 'S':
        return loc.itemTypeShield;
      case 'W':
        return loc.itemTypeWondrousItem;
      case 'G':
        return loc.itemTypeAdventuringGear;
      case 'T':
        return loc.itemTypeTools;
      case 'AF':
        return loc.itemTypeArtisanFocus;
      case 'TG':
        return loc.itemTypeTradeGoods;
      default:
        return typeCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isEditing = widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? loc.edititem : loc.additem),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveItem,
            tooltip: loc.save,
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
                      loc.itemdetails,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '${loc.name} *',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedTypeCode,
                      decoration: InputDecoration(
                        labelText: loc.type,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                      items: typeNames.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(_getLocalizedTypeName(loc, entry.key)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTypeCode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            decoration: InputDecoration(
                              labelText: loc.weight,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _valueController,
                            decoration: InputDecoration(
                              labelText: '${loc.value} (gp)',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: loc.description,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      minLines: 5,
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
