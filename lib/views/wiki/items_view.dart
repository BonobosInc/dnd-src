import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class AllItemsPage extends StatefulWidget {
  final List<ItemData> items;
  final bool importItem;
  final Function(ItemData)? onEdit;
  final Function(ItemData)? onDelete;

  const AllItemsPage({
    super.key,
    required this.items,
    this.importItem = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  AllItemsPageState createState() => AllItemsPageState();
}

class AllItemsPageState extends State<AllItemsPage> {
  final Set<ItemData> _selectedItems = {};
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

  String _searchText = '';
  bool _sortByName = true;
  String? _selectedType;
  late List<ItemData> _filteredItemsCache;
  late List<String> _uniqueTypes;

  bool isSearchVisible = false;
  late String _activeFilter;
  FocusNode searchFocusNode = FocusNode();
  TextEditingController searchController = TextEditingController();

  String _getTypeName(BuildContext context, String typeCode) {
    final loc = AppLocalizations.of(context)!;
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

  void _onItemSelected(ItemData item, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _filteredItemsCache = _computeFilteredItems();
    _uniqueTypes = _getUniqueTypes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = AppLocalizations.of(context)!;

      setState(() {
        _activeFilter = loc.sortbyname;
      });
    });
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AllItemsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItemsCache = _computeFilteredItems();
      _uniqueTypes = _getUniqueTypes();
    }
  }

  List<String> _getUniqueTypes() {
    Set<String> typeSet = {};
    for (var item in widget.items) {
      if (item.type.isNotEmpty) {
        typeSet.add(item.type);
      }
    }

    List<String> typeList = typeSet.toList();
    typeList.sort();

    return typeList;
  }

  List<ItemData> _computeFilteredItems() {
    List<ItemData> filteredList = widget.items
        .where((item) =>
            item.name.toLowerCase().contains(_searchText.toLowerCase()) &&
            (_selectedType == null || item.type == _selectedType))
        .toList();

    if (_sortByName) {
      filteredList.sort((a, b) => a.name.compareTo(b.name));
    } else {
      filteredList.sort((a, b) => a.type.compareTo(b.type));
    }

    return filteredList;
  }

  void _navigateToItemDetail(ItemData item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailPage(
          item: item,
          onEdit: widget.onEdit,
          onDelete: (name) async {
            if (widget.onDelete != null) {
              widget.onDelete!(item);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: isSearchVisible
            ? TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                decoration: InputDecoration(
                  hintText: '${loc.search}...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                    _filteredItemsCache = _computeFilteredItems();
                  });
                },
              )
            : Text(loc.allitems),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible;
                if (isSearchVisible) {
                  searchFocusNode.requestFocus();
                } else {
                  _searchText = '';
                  searchController.clear();
                  searchFocusNode.unfocus();
                  _filteredItemsCache = _computeFilteredItems();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: loc.filterandsort,
            onSelected: (value) {
              setState(() {
                _activeFilter = value;
                if (_activeFilter == loc.sortbyname) {
                  _sortByName = true;
                  _selectedType = null;
                } else if (_activeFilter == loc.sortbytype) {
                  _sortByName = false;
                  _selectedType = null;
                } else {
                  _sortByName = true;
                  _selectedType = _activeFilter;
                }
                _filteredItemsCache = _computeFilteredItems();
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: loc.sortbyname,
                child: Row(
                  children: [
                    if (_activeFilter == loc.sortbyname)
                      const Icon(Icons.check, size: 18, color: Colors.blue),
                    Text(loc.sortbyname),
                  ],
                ),
              ),
              PopupMenuItem(
                value: loc.sortbytype,
                child: Row(
                  children: [
                    if (_activeFilter == loc.sortbytype)
                      const Icon(Icons.check, size: 18, color: Colors.blue),
                    Text(loc.sortbytype),
                  ],
                ),
              ),
              ..._uniqueTypes.map(
                (type) => PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      if (_activeFilter == type)
                        const Icon(Icons.check, size: 18, color: Colors.blue),
                      Text(_getTypeName(context, type)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.importItem)
            IconButton(
              tooltip: loc.add,
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop(_selectedItems.toList());
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItemsCache.length,
              itemBuilder: (context, index) {
                final item = _filteredItemsCache[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                      '${_getTypeName(context, item.type)} - ${item.weight} - ${item.value} gp'),
                  trailing: widget.importItem
                      ? GestureDetector(
                          onTap: () {
                            _navigateToItemDetail(item);
                          },
                          child: Checkbox(
                            value: _selectedItems.contains(item),
                            onChanged: (isSelected) {
                              _onItemSelected(item, isSelected!);
                            },
                          ),
                        )
                      : null,
                  onTap: () {
                    if (widget.importItem) {
                      _onItemSelected(item, !_selectedItems.contains(item));
                    } else {
                      _navigateToItemDetail(item);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ItemDetailPage extends StatelessWidget {
  final ItemData item;
  final Function(ItemData)? onEdit;
  final Function(String)? onDelete;

  const ItemDetailPage({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    // Helper to get localized type name
    String getTypeName(String typeCode) {
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: loc.edit,
              onPressed: () async {
                onEdit!(item);
                // Don't pop - let the navigation happen naturally
                // The edit page will be pushed on top of this detail page
              },
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: loc.delete,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(loc.delete),
                    content: Text('${loc.delete} ${item.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(loc.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(loc.delete),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  onDelete!(item.name);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(loc, '${loc.type}:',
                getTypeName(item.type)),
            _buildInfoRow(loc, '${loc.weight}:', item.weight),
            _buildInfoRow(loc, '${loc.value}:', '${item.value} gp'),
            const SizedBox(height: 20),
            Text(
              '${loc.description}:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(item.text),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(AppLocalizations loc, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
