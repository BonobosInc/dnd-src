import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/classes/remote_client.dart';
import 'package:dnd/views/session/remote_client_view.dart';
import 'package:flutter/material.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteSessionView extends StatefulWidget {
  final ProfileManager profileManager;
  final List<Character>? profiles;

  const RemoteSessionView({
    super.key,
    required this.profileManager,
    this.profiles,
  });

  @override
  State<RemoteSessionView> createState() => _RemoteSessionViewState();
}

class _RemoteSessionViewState extends State<RemoteSessionView> {
  final RemoteClient _remoteClient = RemoteClient();
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _sessionCodeController = TextEditingController();
  final TextEditingController _sessionNameController = TextEditingController();

  bool _isHost = false;
  bool _isConnecting = false;
  String? _savedServerUrl;
  Character? _selectedCharacter;
  Map<String, String>? _savedDMSession;

  @override
  void initState() {
    super.initState();
    _loadSavedServerUrl();
    _checkForSavedDMSession();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _sessionCodeController.dispose();
    _sessionNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('remote_server_url');
    if (url != null) {
      setState(() {
        _savedServerUrl = url;
        _serverUrlController.text = url;
      });
    }
  }

  Future<void> _checkForSavedDMSession() async {
    final savedSession = await _remoteClient.loadSavedDMSession();
    if (savedSession != null && mounted) {
      setState(() {
        _savedDMSession = savedSession;
      });
    }
  }

  Future<void> _saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remote_server_url', url);
  }

  Future<void> _reconnectAsDM() async {
    if (_savedDMSession == null) return;

    setState(() => _isConnecting = true);

    try {
      final dmChar = Character(
        id: 0,
        name: 'Dungeon Master',
      );

      final success = await _remoteClient.joinSession(
        _savedDMSession!['url']!,
        _savedDMSession!['code']!,
        dmChar,
        isDM: true,
        dmToken: _savedDMSession!['token'],
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RemoteClientView(
              client: _remoteClient,
              playerName: 'Dungeon Master',
              isDM: true,
              profileManager: widget.profileManager,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        // Session might be expired, clear it
        await _remoteClient.clearSavedDMSession();
        setState(() => _savedDMSession = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired or no longer exists')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reconnecting: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _createSession() async {
    final loc = AppLocalizations.of(context)!;

    if (_serverUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enterServerUrl)),
      );
      return;
    }

    final sessionName = _sessionNameController.text.trim().isEmpty
        ? loc.unnamedSession
        : _sessionNameController.text.trim();

    setState(() => _isConnecting = true);

    try {
      final serverUrl = _serverUrlController.text.trim();
      await _saveServerUrl(serverUrl);

      final code = await _remoteClient.createSession(
        serverUrl,
        sessionName,
        'DM', // You could make this configurable
      );

      if (code != null) {
        // Show the code to the user
        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardColor,
            title: Text(
              'Session Created!',
              style: TextStyle(color: AppColors.textColorLight),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share this code with your players:',
                  style: TextStyle(color: AppColors.textColorLight),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentPink),
                  ),
                  child: SelectableText(
                    code,
                    style: TextStyle(
                      color: AppColors.accentPink,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.ok, style: TextStyle(color: AppColors.accentPink)),
              ),
            ],
          ),
        );

        // Now join the session as DM
        if (_selectedCharacter == null) {
          // Create a temporary DM character
          final dmChar = Character(
            id: 0,
            name: 'Dungeon Master',
          );

          final success = await _remoteClient.joinSession(
            serverUrl,
            code,
            dmChar,
            isDM: true,
          );

          if (success && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RemoteClientView(
                  client: _remoteClient,
                  playerName: 'Dungeon Master',
                  isDM: true,
                  profileManager: widget.profileManager,
                ),
              ),
            );
          }
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.error}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _joinSession() async {
    final loc = AppLocalizations.of(context)!;

    if (_serverUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enterServerUrl)),
      );
      return;
    }

    if (_sessionCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter session code')),
      );
      return;
    }

    if (_selectedCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseSelectCharacter)),
      );
      return;
    }

    final code = _sessionCodeController.text.trim().toUpperCase();

    if (!RemoteClient.validateSessionCode(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid session code format')),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final serverUrl = _serverUrlController.text.trim();
      await _saveServerUrl(serverUrl);

      // Load character stats
      await widget.profileManager.selectProfile(_selectedCharacter!);

      final success = await _remoteClient.joinSession(
        serverUrl,
        code,
        _selectedCharacter!,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RemoteClientView(
              client: _remoteClient,
              playerName: _selectedCharacter!.name,
              isDM: false,
              profileManager: widget.profileManager,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join session')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.error}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Text(
          'Remote Session',
          style: TextStyle(color: AppColors.textColorLight),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textColorLight,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isConnecting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.accentPink),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting...',
                    style: TextStyle(color: AppColors.textColorLight),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Show reconnect option if DM session exists
                  if (_savedDMSession != null) ...[
                    Card(
                      color: AppColors.accentPurple.withValues(alpha: 0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.accentPurple),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Active DM Session Found',
                                    style: TextStyle(
                                      color: AppColors.textColorLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Code: ${_savedDMSession!['code']}',
                              style: TextStyle(
                                color: AppColors.accentPurple,
                                fontFamily: 'monospace',
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sessionHost,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reconnect as DM'),
                              onPressed: () => _reconnectAsDM(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Server URL input
                  Text(
                    'Server URL',
                    style: TextStyle(
                      color: AppColors.textColorLight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _serverUrlController,
                    style: TextStyle(color: AppColors.textColorLight),
                    decoration: InputDecoration(
                      hintText: 'http://bonodnd.duckdns.org:31333',
                      hintStyle: TextStyle(color: AppColors.textColorDark),
                      filled: true,
                      fillColor: AppColors.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Host or Join selection
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text(loc.hostGame),
                          selected: _isHost,
                          onSelected: (selected) => setState(() => _isHost = true),
                          selectedColor: AppColors.sessionHost,
                          backgroundColor: AppColors.cardColor,
                          labelStyle: TextStyle(
                            color: _isHost
                                ? Colors.white
                                : AppColors.textColorLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ChoiceChip(
                          label: Text(loc.joinGame),
                          selected: !_isHost,
                          onSelected: (selected) => setState(() => _isHost = false),
                          selectedColor: AppColors.sessionJoin,
                          backgroundColor: AppColors.cardColor,
                          labelStyle: TextStyle(
                            color: !_isHost
                                ? Colors.white
                                : AppColors.textColorLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Host section
                  if (_isHost) ...[
                    Text(
                      'Session Name',
                      style: TextStyle(
                        color: AppColors.textColorLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sessionNameController,
                      style: TextStyle(color: AppColors.textColorLight),
                      decoration: InputDecoration(
                        hintText: loc.enterSessionNameHint,
                        hintStyle: TextStyle(color: AppColors.textColorDark),
                        filled: true,
                        fillColor: AppColors.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sessionHost,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle),
                      label: Text('Create Session', style: TextStyle(fontSize: 18)),
                      onPressed: _createSession,
                    ),
                  ],

                  // Join section
                  if (!_isHost) ...[
                    Text(
                      'Session Code',
                      style: TextStyle(
                        color: AppColors.textColorLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sessionCodeController,
                      style: TextStyle(
                        color: AppColors.textColorLight,
                        fontSize: 18,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'ABC-DEF-GHI-JKL-MNO-PQR',
                        hintStyle: TextStyle(color: AppColors.textColorDark),
                        filled: true,
                        fillColor: AppColors.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderColor),
                        ),
                      ),
                      onChanged: (value) {
                        // Auto-format with dashes
                        String formatted = value.toUpperCase().replaceAll('-', '');
                        if (formatted.length > 18) {
                          formatted = formatted.substring(0, 18);
                        }
                        String withDashes = '';
                        for (int i = 0; i < formatted.length; i++) {
                          if (i > 0 && i % 3 == 0) {
                            withDashes += '-';
                          }
                          withDashes += formatted[i];
                        }
                        if (withDashes != value) {
                          _sessionCodeController.value = TextEditingValue(
                            text: withDashes,
                            selection: TextSelection.collapsed(
                              offset: withDashes.length,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Character selection
                    Text(
                      loc.chooseCharacter,
                      style: TextStyle(
                        color: AppColors.textColorLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Character>(
                          value: _selectedCharacter,
                          isExpanded: true,
                          dropdownColor: AppColors.cardColor,
                          style: TextStyle(color: AppColors.textColorLight),
                          hint: Text(
                            loc.selectYourCharacter,
                            style: TextStyle(color: AppColors.textColorDark),
                          ),
                          items: widget.profiles?.map((character) {
                            return DropdownMenuItem<Character>(
                              value: character,
                              child: Text(character.name),
                            );
                          }).toList(),
                          onChanged: (character) {
                            setState(() => _selectedCharacter = character);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sessionJoin,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.login),
                      label: Text(loc.join, style: TextStyle(fontSize: 18)),
                      onPressed: _joinSession,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
