import 'dart:io';
import 'package:dnd/views/character/mainstats_view.dart';
import 'package:dnd/views/character/stats_view.dart';
import 'package:dnd/views/appstatus.dart';
import 'package:dnd/views/settings_view.dart';
import 'package:dnd/views/session/client_view.dart';
import 'package:dnd/views/session/host.dart';
import 'package:dnd/views/session/session_view.dart';
import 'package:dnd/classes/server.dart';
import 'package:dnd/classes/client.dart';
import 'package:dnd/classes/session_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/views/bag_view.dart';
import 'package:dnd/views/notes_view.dart';
import 'package:dnd/views/weapon_view.dart';
import 'package:dnd/views/wiki_view.dart';
import 'package:dnd/configs/defines.dart';
import 'package:dnd/configs/colours.dart';
import 'spell_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dnd/l10n/app_localizations.dart';

class CharacterView extends StatefulWidget {
  final ProfileManager profileManager;
  final WikiParser wikiParser;
  final Character profile;
  final DnDMulticastServer? server;
  final DnDClient? client;

  const CharacterView({
    super.key,
    required this.profileManager,
    required this.wikiParser,
    required this.profile,
    this.server,
    this.client,
  });

  @override
  CharacterViewState createState() => CharacterViewState();
}

class CharacterViewState extends State<CharacterView> {
  String name = "Charakter";
  int level = 0;
  int xp = 0;
  final SessionManager _sessionManager = SessionManager();

  dynamic _profileImagePath = AssetImage('assets/images/default.png');

  final List<int> xpThresholds = [
    0,
    300,
    900,
    2700,
    6500,
    14000,
    23000,
    34000,
    48000,
    64000,
    85000,
    100000,
    120000,
    140000,
    165000,
    195000,
    225000,
    265000,
    305000,
    355000,
  ];

  GlobalKey<MainStatsPageState> mainStatsPageKey =
      GlobalKey<MainStatsPageState>();

  @override
  void initState() {
    super.initState();
    name = widget.profile.name;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCharacterData();
    });
    _getProfileImagePath();
  }

  Future<void> _loadCharacterData() async {
    final loc = AppLocalizations.of(context)!;

    List<Map<String, dynamic>> result =
        await widget.profileManager.getProfileInfo();
    List<Map<String, dynamic>> stats = await widget.profileManager.getStats();

    if (result.isNotEmpty) {
      Map<String, dynamic> characterData = result.first;
      setState(() {
        name = characterData[Defines.infoName] ?? loc.unknownchar;
      });
    }
    if (stats.isNotEmpty) {
      Map<String, dynamic> characterData = stats.first;
      setState(() {
        level = characterData[Defines.statLevel]!;
        xp = characterData[Defines.statXP]!;
      });
    }
  }

  // Send stats to server if connected to a session
  Future<void> sendStatsToServer() async {
    if (_sessionManager.isConnected && _sessionManager.client != null) {
      final hp = mainStatsPageKey.currentState?.currentHP;
      final maxHp = mainStatsPageKey.currentState?.maxHP;
      final tempHp = mainStatsPageKey.currentState?.tempHP;
      final ac = mainStatsPageKey.currentState?.armor;
      print(
          '📤 sendStatsToServer: HP=$hp, maxHP=$maxHp, tempHP=$tempHp, AC=$ac');
      if (hp != null && ac != null) {
        await _sessionManager.client!.sendStats({
          'HP': hp,
          'maxHP': maxHp,
          'tempHP': tempHp ?? 0,
          'AC': ac,
        });
      }
    }
  }

  void _showLevelDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int tempLevel = level;

        return StatefulBuilder(
          builder: (BuildContext context, setStateDialog) {
            return AlertDialog(
              title: Text(loc.level),
              content: SizedBox(
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 24),
                      onPressed: () {
                        if (tempLevel > 1) {
                          setStateDialog(() {
                            tempLevel--;
                          });
                        }
                      },
                    ),
                    Text(
                      tempLevel.toString(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 24),
                      onPressed: () {
                        if (tempLevel < 20) {
                          setStateDialog(() {
                            tempLevel++;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(loc.abort),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(loc.save),
                  onPressed: () async {
                    setState(() {
                      level = tempLevel;
                      xp = xpThresholds[level - 1];
                    });

                    await widget.profileManager.updateStats(
                      field: Defines.statLevel,
                      value: level,
                    );
                    await widget.profileManager.updateStats(
                      field: Defines.statXP,
                      value: xp,
                    );

                    if (mainStatsPageKey.currentState != null) {
                      mainStatsPageKey.currentState!.refreshContent();
                    }

                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showXPDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int tempXP = xp;
        TextEditingController controller =
            TextEditingController(text: tempXP.toString());

        return AlertDialog(
          title: Text(loc.xp),
          content: _buildTextField(
            label: loc.enterxpamount,
            controller: controller,
            onChanged: (value) {
              tempXP = int.tryParse(value) ?? 0;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text(loc.abort),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(loc.save),
              onPressed: () async {
                setState(() {
                  xp = tempXP;
                  level = _calculateLevelFromXP(xp);
                });

                await widget.profileManager.updateStats(
                  field: Defines.statXP,
                  value: xp,
                );
                await widget.profileManager.updateStats(
                  field: Defines.statLevel,
                  value: level,
                );

                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int _calculateLevelFromXP(int xp) {
    for (int i = xpThresholds.length - 1; i >= 0; i--) {
      if (xp >= xpThresholds[i]) return i + 1;
    }
    return 1;
  }

  Future<List<Map<String, dynamic>>> _getSpellSlots() async {
    final spellSlots = await widget.profileManager.getSpellSlots();

    final List<Map<String, dynamic>> updatedSlots = [];
    for (var slot in spellSlots) {
      final spellSlot = {
        'spellslot': slot['spellslot'],
        'total': slot['total'] ?? 0,
      };
      updatedSlots.add(spellSlot);
    }
    return updatedSlots;
  }

  Future<List<Map<String, dynamic>>> _getTrackers() async {
    final trackers = await widget.profileManager.getTracker();

    return trackers;
  }

  Future<void> _longRest() async {
    final loc = AppLocalizations.of(context)!;
    final shouldProceed =
        await _showConfirmationDialog(loc.longrest, loc.longrestconfirm);

    if (!shouldProceed) return;

    final stats = await widget.profileManager.getStats();

    final currentHD = stats.first[Defines.statCurrentHitDice];
    final maxHD = stats.first[Defines.statMaxHitDice];

    var hitDiceToAdd = (maxHD / 2).floor();

    if (hitDiceToAdd == 0) {
      hitDiceToAdd = 1;
    }

    final updatedHitDice = (currentHD + hitDiceToAdd).clamp(0, maxHD);

    widget.profileManager.updateStats(
        field: Defines.statCurrentHP, value: stats.first[Defines.statMaxHP]);
    widget.profileManager.updateStats(field: Defines.statTempHP, value: 0);

    widget.profileManager
        .updateStats(field: Defines.statCurrentHitDice, value: updatedHitDice);

    final spellSlots = await _getSpellSlots();
    for (var spellSlot in spellSlots) {
      await widget.profileManager.updateSpellSlots(
        spellslot: spellSlot['spellslot'],
        spent: spellSlot['total'],
      );
    }

    final trackers = await _getTrackers();
    for (var tracker in trackers) {
      if (tracker['type'] == 'long' || tracker['type'] == 'short') {
        await widget.profileManager.updateTracker(
          uuid: tracker['ID'],
          value: tracker['max'],
        );
      }
    }

    if (mainStatsPageKey.currentState != null) {
      mainStatsPageKey.currentState!.refreshContent();
    }
  }

  Future<void> _shortRest() async {
    final loc = AppLocalizations.of(context)!;
    final shouldProceed =
        await _showConfirmationDialog(loc.shortrest, loc.shortrestconfirm);

    if (!shouldProceed) return;

    final trackers = await _getTrackers();

    for (var tracker in trackers) {
      if (tracker['type'] == 'short') {
        await widget.profileManager.updateTracker(
          uuid: tracker['ID'],
          value: tracker['max'],
        );
      }
    }

    if (mainStatsPageKey.currentState != null) {
      mainStatsPageKey.currentState!.refreshContent();
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final loc = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: Text(loc.no),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(loc.yes),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildTextField({
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

  void _showProfileImageDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: _profileImagePath is AssetImage
                    ? Image(
                        image: _profileImagePath,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        _profileImagePath as File,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final pickedFile = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );

                  if (pickedFile != null) {
                    File file = File(pickedFile.files.single.path!);
                    File savedFilePath = await _uploadImage(file);
                    if (context.mounted) Navigator.of(context).pop();
                    setState(() {
                      _profileImagePath = savedFilePath;
                    });

                    if (context.mounted) {
                      _showProfileImageDialog(context);
                    }
                  }
                },
                child: Text(loc.addimage),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _showDeleteConfirmationDialog(context);
                },
                child: Text(loc.deleteimage),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.deleteimage),
          content: Text(loc.deleteimageconfirm),
          actions: [
            TextButton(
              child: Text(loc.abort),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(loc.delete),
              onPressed: () async {
                if (_profileImagePath is File) {
                  File profileImageFile = _profileImagePath as File;

                  if (await profileImageFile.exists()) {
                    await profileImageFile.delete();
                  }
                }

                setState(() {
                  _profileImagePath = AssetImage('assets/images/default.png');
                });
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  _showProfileImageDialog(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<File> _uploadImage(File pickedFile) async {
    String savedFilePath = '';

    if (Platform.isWindows) {
      bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
      Directory directory = isDebugMode
          ? Directory('./temp')
          : await getApplicationSupportDirectory();

      savedFilePath = '${directory.path}/$name.png';

      await pickedFile.copy(savedFilePath);
    } else {
      Directory appSupportDir = await getApplicationSupportDirectory();
      savedFilePath = '${appSupportDir.path}/$name.png';

      await pickedFile.copy(savedFilePath);
    }

    return File(savedFilePath);
  }

  Future<void> _getProfileImagePath() async {
    String imagePath = '';

    if (Platform.isWindows) {
      bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
      Directory directory = isDebugMode
          ? Directory('./temp')
          : await getApplicationSupportDirectory();

      imagePath = '${directory.path}/$name.png';
    } else {
      Directory appSupportDir = await getApplicationSupportDirectory();
      imagePath = '${appSupportDir.path}/$name.png';
    }

    File profileImageFile = File(imagePath);

    if (profileImageFile.existsSync()) {
      setState(() {
        _profileImagePath = profileImageFile;
      });
    } else {
      setState(() {
        _profileImagePath = AssetImage('assets/images/default.png');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          widget.profileManager.closeDB();
          return;
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _showProfileImageDialog(context);
                  },
                  child: ClipOval(
                    child: _profileImagePath is AssetImage
                        ? Image(
                            image: _profileImagePath as AssetImage,
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            _profileImagePath as File,
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                SizedBox(width: 10),
                Text(name),
              ],
            ),
            backgroundColor: AppColors.appBarColor,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(48.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return TabBar(
                      tabs: [
                        Tab(icon: Icon(MdiIcons.swordCross)),
                        Tab(icon: Icon(Icons.list)),
                      ],
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              bool isWideScreen = constraints.maxWidth >= 600;
              if (isWideScreen) {
                return Row(
                  children: [
                    Expanded(
                      child: MainStatsPage(
                        key: mainStatsPageKey,
                        profileManager: widget.profileManager,
                        wikiParser: widget.wikiParser,
                        onStatsChanged: sendStatsToServer,
                      ),
                    ),
                    Expanded(
                      child: StatsPage(
                        profileManager: widget.profileManager,
                      ),
                    ),
                  ],
                );
              } else {
                return TabBarView(
                  children: [
                    MainStatsPage(
                      key: mainStatsPageKey,
                      profileManager: widget.profileManager,
                      wikiParser: widget.wikiParser,
                      onStatsChanged: sendStatsToServer,
                    ),
                    StatsPage(
                      profileManager: widget.profileManager,
                    ),
                  ],
                );
              }
            },
          ),
          endDrawer: SizedBox(
            width: 250,
            child: Drawer(
              backgroundColor: AppColors.primaryColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        SizedBox(
                          height: 170,
                          child: DrawerHeader(
                            decoration: BoxDecoration(
                              color: AppColors.appBarColor,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: _showLevelDialog,
                                      child: Text(
                                        '${loc.level}: $level',
                                        style: TextStyle(
                                          color: AppColors.textColorLight,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<int>(
                                      tooltip: "",
                                      icon: const Icon(Icons.settings),
                                      color: AppColors.primaryColor,
                                      iconSize: 28.0,
                                      onSelected: (value) async {
                                        if (value == 1) {
                                          await _longRest();
                                        } else if (value == 2) {
                                          await _shortRest();
                                        } else if (value == 3) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const SettingsPage(),
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          PopupMenuItem<int>(
                                            value: 1,
                                            child: Text(loc.longrest),
                                          ),
                                          PopupMenuItem<int>(
                                            value: 2,
                                            child: Text(loc.shortrest),
                                          ),
                                          PopupMenuItem<int>(
                                            value: 3,
                                            child: Text(loc.settings),
                                          ),
                                        ];
                                      },
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: _showXPDialog,
                                  child: Text(
                                    '${loc.xp}: $xp',
                                    style: TextStyle(
                                      color: AppColors.textColorLight,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            loc.spells,
                            style: TextStyle(color: AppColors.textColorLight),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SpellManagementPage(
                                  profileManager: widget.profileManager,
                                  wikiParser: widget.wikiParser,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(
                            loc.weapons,
                            style: TextStyle(color: AppColors.textColorLight),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WeaponPage(
                                  profileManager: widget.profileManager,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(
                            loc.notes,
                            style: TextStyle(color: AppColors.textColorLight),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotesPage(
                                  profileManager: widget.profileManager,
                                  wikiParser: widget.wikiParser,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(
                            loc.equipments,
                            style: TextStyle(color: AppColors.textColorLight),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BagPage(
                                  profileManager: widget.profileManager,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(
                            loc.wiki,
                            style: TextStyle(color: AppColors.textColorLight),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WikiPage(
                                  wikiParser: widget.wikiParser,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(
                            loc.session,
                            style: TextStyle(color: AppColors.textColorLight),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (_sessionManager.isHosting) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HostPage(
                                    server: _sessionManager.server!,
                                    sessionName: _sessionManager.server!.name,
                                    wikiParser: widget.wikiParser,
                                  ),
                                ),
                              );
                            } else if (_sessionManager.isConnected) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClientPage(
                                    client: _sessionManager.client!,
                                    playerName:
                                        _sessionManager.client!.playerName ??
                                            'Unknown Player',
                                    isFromLobby: false,
                                    profileManager: widget.profileManager,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LobbyPage(
                                    server: _sessionManager.getOrCreateServer(),
                                    client: _sessionManager.getOrCreateClient(),
                                    profiles: widget.profileManager.profiles,
                                    profileManager: widget.profileManager,
                                    wikiParser: widget.wikiParser,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: IconButton(
                          icon: Icon(Icons.info_outline,
                              color: AppColors.textColorLight),
                          onPressed: () {
                            showAppStatusDialog(context);
                          },
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
