import 'dart:async';
import 'dart:convert';
import 'package:dnd/classes/profile_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteClient {
  String? serverUrl; // e.g., "http://192.168.1.100:4040" or "https://yourdomain.com"
  String? sessionCode; // 6-part code
  String? dmToken; // Token for DM reconnection
  String? playerName;
  String? sessionName;
  bool isDM = false;
  bool get isConnected => _channel != null && sessionCode != null;

  WebSocketChannel? _channel;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  final List<Map<String, dynamic>> playersData = [];
  final List<Map<String, dynamic>> monstersData = [];
  Map<String, dynamic>? sessionSettings;

  final StreamController<List<Map<String, dynamic>>> _playerListController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get playerListStream =>
      _playerListController.stream;

  /// Validate session code format (ABC-DEF-GHI-JKL-MNO-PQR)
  static bool validateSessionCode(String code) {
    final parts = code.split('-');
    if (parts.length != 6) return false;
    return parts.every((part) => part.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(part));
  }

  /// Create a new session on the remote server
  Future<String?> createSession(String serverUrl, String sessionName, String dmName) async {
    try {
      this.serverUrl = serverUrl;
      final uri = Uri.parse('$serverUrl/session/create');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionName': sessionName,
          'dmName': dmName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final code = data['sessionCode'] as String?;
        dmToken = data['dmToken'] as String?;  // Save DM token
        isDM = true;

        // Save session info for reconnection
        await _saveSessionInfo(code!, dmToken!, serverUrl);

        if (kDebugMode) print('✅ Created session: $code, DM Token saved');
        return code;
      } else {
        if (kDebugMode) print('❌ Failed to create session: ${response.body}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error creating session: $e');
      return null;
    }
  }

  /// Save session info for DM reconnection
  Future<void> _saveSessionInfo(String code, String token, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dm_session_code', code);
    await prefs.setString('dm_session_token', token);
    await prefs.setString('dm_session_url', url);
    await prefs.setString('dm_session_timestamp', DateTime.now().toIso8601String());
  }

  /// Load saved DM session info
  Future<Map<String, String>?> loadSavedDMSession() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('dm_session_code');
    final token = prefs.getString('dm_session_token');
    final url = prefs.getString('dm_session_url');
    final timestamp = prefs.getString('dm_session_timestamp');

    if (code != null && token != null && url != null && timestamp != null) {
      // Check if session is still valid (within 24 hours)
      final savedTime = DateTime.parse(timestamp);
      final age = DateTime.now().difference(savedTime);

      if (age.inHours < 24) {
        return {
          'code': code,
          'token': token,
          'url': url,
        };
      } else {
        // Clear expired session
        await clearSavedDMSession();
      }
    }

    return null;
  }

  /// Clear saved DM session
  Future<void> clearSavedDMSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dm_session_code');
    await prefs.remove('dm_session_token');
    await prefs.remove('dm_session_url');
    await prefs.remove('dm_session_timestamp');
  }

  /// Join an existing session with a 6-part code
  Future<bool> joinSession(String serverUrl, String code, Character player, {bool isDM = false, String? dmToken}) async {
    try {
      // Validate code format
      final upperCode = code.toUpperCase();
      if (!validateSessionCode(upperCode)) {
        if (kDebugMode) print('❌ Invalid session code format');
        return false;
      }

      this.serverUrl = serverUrl;
      this.sessionCode = upperCode;
      this.playerName = player.name;
      this.isDM = isDM;
      this.dmToken = dmToken;

      // Get session info first
      final infoUri = Uri.parse('$serverUrl/session/$upperCode');
      final infoResponse = await http.get(infoUri);

      if (infoResponse.statusCode != 200) {
        if (kDebugMode) print('❌ Session not found');
        return false;
      }

      final sessionInfo = jsonDecode(infoResponse.body);
      sessionName = sessionInfo['sessionName'];

      // Connect to WebSocket
      await connectToWebSocket(serverUrl, upperCode, player.name, isDM, dmToken);

      if (kDebugMode) print('✅ Joined session: $sessionName');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error joining session: $e');
      return false;
    }
  }

  /// Connect to the WebSocket endpoint
  Future<void> connectToWebSocket(String serverUrl, String code, String name, bool isDM, String? dmToken) async {
    try {
      // Convert http(s) to ws(s)
      final wsUrl = serverUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/ws/$code');

      _channel = WebSocketChannel.connect(uri);

      // Send join message with DM token if applicable
      final joinMessage = {
        'type': 'join',
        'name': name,
        'isDM': isDM,
      };

      if (isDM && dmToken != null) {
        joinMessage['dmToken'] = dmToken;
      }

      _channel!.sink.add(jsonEncode(joinMessage));

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            _handleMessage(data);
          } catch (e) {
            if (kDebugMode) print('⚠️ Error parsing message: $e');
          }
        },
        onError: (error) {
          if (kDebugMode) print('⚠️ WebSocket error: $error');
        },
        onDone: () {
          if (kDebugMode) print('🔌 WebSocket connection closed');
          _handleDisconnect();
        },
      );

      if (kDebugMode) print('🔗 Connected to WebSocket: $uri');
    } catch (e) {
      if (kDebugMode) print('❌ Failed to connect to WebSocket: $e');
      rethrow;
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'welcome':
        playersData.clear();
        playersData.addAll(List<Map<String, dynamic>>.from(data['players'] ?? []));
        monstersData.clear();
        monstersData.addAll(List<Map<String, dynamic>>.from(data['monsters'] ?? []));
        sessionSettings = data['settings'];
        _playerListController.add(playersData);
        if (kDebugMode) print('👋 Welcome to session!');
        break;

      case 'player_joined':
        playersData.clear();
        playersData.addAll(List<Map<String, dynamic>>.from(data['players'] ?? []));
        monstersData.clear();
        monstersData.addAll(List<Map<String, dynamic>>.from(data['monsters'] ?? []));
        _playerListController.add(playersData);
        if (kDebugMode) print('👤 Player joined: ${data['name']}');
        break;

      case 'player_left':
        playersData.clear();
        playersData.addAll(List<Map<String, dynamic>>.from(data['players'] ?? []));
        monstersData.clear();
        monstersData.addAll(List<Map<String, dynamic>>.from(data['monsters'] ?? []));
        _playerListController.add(playersData);
        if (kDebugMode) print('👋 Player left: ${data['name']}');
        break;

      case 'stats_update':
        playersData.clear();
        playersData.addAll(List<Map<String, dynamic>>.from(data['players'] ?? []));
        _playerListController.add(playersData);
        if (kDebugMode) print('📊 Stats updated for ${data['name']}');
        break;

      case 'initiative_update':
      case 'monster_added':
      case 'monster_removed':
      case 'turn_update':
        final combatants = List<Map<String, dynamic>>.from(data['combatants'] ?? []);
        playersData.clear();
        monstersData.clear();
        for (var combatant in combatants) {
          if (combatant['isDM'] == false) {
            playersData.add(combatant);
          } else {
            monstersData.add(combatant);
          }
        }
        _playerListController.add(playersData);
        break;

      case 'settings_update':
        sessionSettings = data['settings'];
        break;
    }

    _messageController.add(data);
  }

  void _handleDisconnect() {
    _channel = null;
    sessionCode = null;
    playerName = null;
    sessionName = null;
    playersData.clear();
    monstersData.clear();
    sessionSettings = null;
    if (!_playerListController.isClosed) {
      _playerListController.add([]);
    }
  }

  /// Send player stats update
  Future<void> sendStats(Map<String, dynamic> stats) async {
    if (!isConnected) return;

    _channel?.sink.add(jsonEncode({
      'type': 'stats_update',
      'stats': stats,
    }));

    if (kDebugMode) print('📤 Sent stats update: $stats');
  }

  /// Send initiative update
  Future<void> sendInitiative(int initiative) async {
    if (!isConnected) return;

    _channel?.sink.add(jsonEncode({
      'type': 'initiative_update',
      'initiative': initiative,
    }));

    if (kDebugMode) print('📤 Sent initiative: $initiative');
  }

  /// Add monster (DM only)
  Future<void> addMonster(Map<String, dynamic> monster) async {
    if (!isConnected) return;

    _channel?.sink.add(jsonEncode({
      'type': 'add_monster',
      'monster': monster,
    }));

    if (kDebugMode) print('📤 Added monster: ${monster['name']}');
  }

  /// Remove monster (DM only)
  Future<void> removeMonster(String monsterName) async {
    if (!isConnected) return;

    _channel?.sink.add(jsonEncode({
      'type': 'remove_monster',
      'name': monsterName,
    }));

    if (kDebugMode) print('📤 Removed monster: $monsterName');
  }

  /// Next turn (DM only)
  Future<void> nextTurn() async {
    if (!isConnected) return;

    _channel?.sink.add(jsonEncode({
      'type': 'next_turn',
    }));

    if (kDebugMode) print('📤 Next turn');
  }

  /// Update session settings (DM only)
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    if (!isConnected) return;

    _channel?.sink.add(jsonEncode({
      'type': 'update_settings',
      'settings': settings,
    }));

    if (kDebugMode) print('📤 Updated settings: $settings');
  }

  /// Disconnect from session
  Future<void> disconnect() async {
    if (!isConnected) {
      if (kDebugMode) print('⚠️ Not connected');
      return;
    }

    try {
      // Don't clear DM session info - allow reconnection
      await _channel?.sink.close();
      _handleDisconnect();
      if (kDebugMode) print('👋 Disconnected from session (DM can reconnect)');
    } catch (e) {
      if (kDebugMode) print('⚠️ Error disconnecting: $e');
    }
  }

  void dispose() {
    _messageController.close();
    _playerListController.close();
    _channel?.sink.close();
  }
}
