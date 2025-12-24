import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/configs/defines.dart';
import 'package:dnd/configs/colours.dart';
import 'dart:math';
import 'package:dnd/l10n/app_localizations.dart';

class BagPage extends StatefulWidget {
  final ProfileManager profileManager;

  const BagPage({
    super.key,
    required this.profileManager,
  });

  @override
  BagPageState createState() => BagPageState();
}

class BagPageState extends State<BagPage> {
  final TextEditingController platinController = TextEditingController();
  final TextEditingController goldController = TextEditingController();
  final TextEditingController electrumController = TextEditingController();
  final TextEditingController silverController = TextEditingController();
  final TextEditingController copperController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<Item> items = [];

  int attunementCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
    _fetchItems();
    _fetchAttunementCount();
  }

  _fetchAttunementCount() async {
    List<Map<String, dynamic>> stats = await widget.profileManager.getStats();

    setState(() {
      attunementCount = stats.first[Defines.statAttunmentCount] ?? 0;
    });
  }

  void _updateAttunementCount(int newCount) {
    widget.profileManager
        .updateStats(field: Defines.statAttunmentCount, value: newCount)
        .then((_) {
      _fetchAttunementCount();
    });
  }

  Future<void> _loadCharacterData() async {
    List<Map<String, dynamic>> result =
        await widget.profileManager.getBagItems();

    if (result.isNotEmpty) {
      Map<String, dynamic> characterData = result.first;
      setState(() {
        platinController.text =
            (characterData[Defines.bagPlatin] ?? 0).toString();
        goldController.text = (characterData[Defines.bagGold] ?? 0).toString();
        electrumController.text =
            (characterData[Defines.bagElectrum] ?? 0).toString();
        silverController.text =
            (characterData[Defines.bagSilver] ?? 0).toString();
        copperController.text =
            (characterData[Defines.bagCopper] ?? 0).toString();
      });
    }
  }

  void _onFieldChanged(String field, String value) {
    final int? intValue = int.tryParse(value);
    if (intValue != null) {
      widget.profileManager.updateBag(field: field, value: intValue);
    }
  }

  @override
  void dispose() {
    platinController.dispose();
    goldController.dispose();
    electrumController.dispose();
    silverController.dispose();
    copperController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    List<Map<String, dynamic>> fetchedItems =
        await widget.profileManager.getItems();

    setState(() {
      items.clear();
      for (var item in fetchedItems) {
        items.add(Item(
          name: item['itemname'],
          description: item['description'] ?? '',
          uuid: item['ID'],
          type: item['type'] ?? 'Sonstige',
          amount: item['amount'] ?? 1,
          attunement: item['attunement'] ?? 0,
        ));
      }
      items.sort((a, b) => a.uuid!.compareTo(b.uuid as num));
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.equipments),
        backgroundColor: AppColors.appBarColor,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.accentYellow),
            onPressed: _showAddItemDialog,
            tooltip: loc.additem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildIntegerTextField(
                    loc.platinum,
                    platinController,
                    Defines.bagPlatin,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildIntegerTextField(
                    loc.gold,
                    goldController,
                    Defines.bagGold,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildIntegerTextField(
                    loc.electrum,
                    electrumController,
                    Defines.bagElectrum,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildIntegerTextField(
                    loc.silver,
                    silverController,
                    Defines.bagSilver,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildIntegerTextField(
                    loc.copper,
                    copperController,
                    Defines.bagCopper,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildItemsTiles(loc),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegerTextField(
    String label,
    TextEditingController controller,
    String field,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = min(constraints.maxWidth * 0.18, 90 * 0.18);

        return TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          style: TextStyle(fontSize: fontSize),
          textAlign: TextAlign.center,
          onChanged: (value) => _onFieldChanged(field, value),
        );
      },
    );
  }

  void _showAddItemDialog() {
    var newItem = true;
    _showItemDialog(
        Item(name: '', description: '', type: 'Sonstige', amount: 1, attunement: 0), newItem);
  }

  void _showItemDetails(Item item) {
    var newItem = false;
    _showItemDialog(item, newItem);
  }

  void _showItemDialog(Item item, bool newItem) {
    TextEditingController descriptionController =
        TextEditingController(text: item.description);
    final TextEditingController attunementController =
        TextEditingController(text: item.attunement?.toString());
    final loc = AppLocalizations.of(context)!;

    String? selectedType = item.type;
    int editedAmount = item.amount ?? 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(loc.edititem),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildItemDetailForm(item, descriptionController, loc),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: [
                        DropdownMenuItem(
                            value: 'Gegenstände', child: Text(loc.item)),
                        DropdownMenuItem(
                            value: 'Ausrüstung', child: Text(loc.equipment)),
                        DropdownMenuItem(
                            value: 'Sonstige', child: Text(loc.other)),
                      ],
                      decoration: InputDecoration(
                        labelText: loc.type,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value;
                          item.type = selectedType;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCheckbox(
                      loc.attunement,
                      attunementController.text.isNotEmpty &&
                          attunementController.text != '0',
                      (value) {
                        setState(() {
                          final wasChecked = attunementController.text == '1';
                          final isNowChecked = value == true;

                          if (!wasChecked &&
                              isNowChecked &&
                              attunementCount >= 3) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(loc.attunementlimitReached),
                                content: Text(loc.attunementLimit),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(loc.ok),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          if (isNowChecked) {
                            attunementController.text = '1';
                            attunementCount++;
                            _updateAttunementCount(attunementCount);
                          } else {
                            attunementController.text = '';
                            attunementCount--;
                            _updateAttunementCount(attunementCount);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${loc.amount}:'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (editedAmount > 1) editedAmount--;
                                });
                              },
                            ),
                            Text('$editedAmount'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  editedAmount++;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  height: 36,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(loc.abort),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: TextButton(
                    onPressed: () {
                      item.amount = editedAmount;
                      item.attunement =
                          attunementController.text.isNotEmpty &&
                                  attunementController.text != '0'
                              ? int.parse(attunementController.text)
                              : 0;
                      if (newItem) {
                        _addItem(item, descriptionController.text, loc);
                      } else {
                        _updateItem(item, descriptionController.text, loc);
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: Text(loc.save),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateItem(Item item, String description, AppLocalizations loc) {
    final finalDescription =
        description.isEmpty ? loc.nodescription : description;

    widget.profileManager
        .updateItem(
      itemname: item.name,
      description: finalDescription,
      type: item.type,
      uuid: item.uuid,
      amount: item.amount,
      attunement: item.attunement,
    )
        .then((_) {
      _fetchItems();
    });
  }

  void _addItem(Item item, String description, AppLocalizations loc) {
    final finalDescription =
        description.isEmpty ? loc.nodescription : description;

    widget.profileManager
        .addItem(
            itemname: item.name,
            description: finalDescription,
            type: item.type,
            amount: item.amount,
            attunement: item.attunement)
        .then((_) {
      _fetchItems();
    });
  }

  void _deleteItem(int uuid) async {
    await widget.profileManager.removeItem(uuid);
    _fetchItems();
  }

  Widget _buildItemDetailForm(Item item,
      TextEditingController descriptionController, AppLocalizations loc) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildItemTextField(
          label: loc.name,
          controller: TextEditingController(text: item.name),
          onChanged: (value) => item.name = value,
        ),
        const SizedBox(height: 16),
        _buildDescriptionTextField(descriptionController, loc),
      ],
    );
  }

  Widget _buildItemTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDescriptionTextField(
      TextEditingController controller, AppLocalizations loc) {
    return TextField(
      controller: controller,
      maxLines: 8,
      decoration: InputDecoration(
        labelText: loc.description,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) {
              onChanged(newValue);
            },
          ),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }

  Widget _buildItemsTiles(AppLocalizations loc) {
    items.sort((a, b) => a.uuid!.compareTo(b.uuid!));

    Map<String, List<Item>> groupedItems = {
      loc.item: [],
      loc.equipment: [],
      loc.other: [],
    };

    for (var item in items) {
      String groupKey;
      switch (item.type) {
        case 'Gegenstände':
          groupKey = loc.item;
          break;
        case 'Ausrüstung':
          groupKey = loc.equipment;
          break;
        default:
          groupKey = loc.other;
          break;
      }
      groupedItems[groupKey]!.add(item);
    }

    var nonEmptyCategories =
        groupedItems.entries.where((entry) => entry.value.isNotEmpty).toList();

    return Column(
      children: nonEmptyCategories.map((entry) {
        String category = entry.key;
        List<Item> itemsOfCategory = entry.value;

        List<Widget> categoryWidgets = [
          const Divider(),
          ExpansionTile(
            shape: const Border(),
            title: Text(
              category,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            children: itemsOfCategory.map((item) {
              return Card(
                color: AppColors.cardColor,
                elevation: 4.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(color: AppColors.textColorLight),
                  ),
                  onTap: () => _showItemDetails(item),
                  trailing: SizedBox(
                    width: 35,
                    height: 35,
                    child: IconButton(
                      icon: Icon(Icons.close, color: AppColors.textColorDark),
                      iconSize: 20.0,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _showDeleteConfirmationDialog(item);
                      },
                    ),
                  ),
                  tileColor: AppColors.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              );
            }).toList(),
          ),
        ];
        if (entry == nonEmptyCategories.last) {
          categoryWidgets.add(const Divider());
        }

        return Column(children: categoryWidgets);
      }).toList(),
    );
  }

  void _showDeleteConfirmationDialog(Item item) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.confirmdelete),
          content: Text(loc.confirmItemDelete(item.name)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () {
                _deleteItem(item.uuid!);
                Navigator.of(context).pop(true);
              },
              child: Text(loc.delete),
            ),
          ],
        );
      },
    );
  }
}

class Item {
  String name;
  String description;
  int? uuid;
  String? type;
  int? amount;
  int? attunement;

  Item({
    required this.name,
    required this.description,
    this.uuid,
    required this.type,
    required this.amount,
    this.attunement,
  });
}
