import 'package:dnd/classes/server.dart';
import 'package:dnd/classes/client.dart';
import 'package:dnd/classes/remote_client.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  DnDMulticastServer? _server;
  DnDClient? _client;
  RemoteClient? _remoteClient;

  DnDMulticastServer getOrCreateServer() {
    if (_server == null) {
      _server = DnDMulticastServer();
    }
    return _server!;
  }

  DnDClient getOrCreateClient() {
    _client ??= DnDClient();
    return _client!;
  }

  RemoteClient getOrCreateRemoteClient() {
    _remoteClient ??= RemoteClient();
    return _remoteClient!;
  }

  DnDMulticastServer? get server => _server;
  DnDClient? get client => _client;
  RemoteClient? get remoteClient => _remoteClient;

  bool get isHosting => _server?.serverStarted ?? false;
  bool get isConnected => _client?.isConnected ?? false;
  bool get isRemoteConnected => _remoteClient?.isConnected ?? false;

  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.stop();
      _server = null;
    }
  }

  Future<void> stopClient() async {
    if (_client != null) {
      await _client!.disconnect();
      _client = null;
    }
  }

  Future<void> stopRemoteClient() async {
    if (_remoteClient != null) {
      await _remoteClient!.disconnect();
      _remoteClient = null;
    }
  }

  Future<void> stopAll() async {
    await stopServer();
    await stopClient();
    await stopRemoteClient();
  }

  void clearServer() {
    _server = null;
  }

  void clearClient() {
    _client = null;
  }

  void clearRemoteClient() {
    _remoteClient = null;
  }

  void clearAll() {
    _server = null;
    _client = null;
    _remoteClient = null;
  }
}
