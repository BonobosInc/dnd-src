import 'package:flutter/material.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/classes/server.dart';

class HostPage extends StatefulWidget {
  final DnDMulticastServer server;
  final String sessionName;

  const HostPage({super.key, required this.server, required this.sessionName});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  bool _stopping = false;

  Future<void> _stopHosting() async {
    if (_stopping) return;
    final shouldStop = await _showStopConfirmationDialog();
    if (shouldStop != true) return;
    setState(() => _stopping = true);
    await widget.server.stop();
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Future<bool?> _showStopConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Stop Hosting'),
          content: const Text('Are you sure you want to stop hosting this session? All players will be disconnected.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Stop Hosting'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Text(
          '🧙 Hosting: ${widget.sessionName}',
          style: TextStyle(color: AppColors.textColorLight),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textColorLight,
          onPressed: _stopHosting,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session Info',
                style: TextStyle(
                    color: AppColors.textColorLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'IP Address: ${widget.server.localIp ?? 'Unknown'}\n'
              'Port: ${widget.server.port}',
              style: TextStyle(color: AppColors.textColorDark),
            ),
            const Divider(height: 30, color: Colors.grey),
            Text('Connected Players:',
                style: TextStyle(
                    color: AppColors.textColorLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.server.playerStream,
                builder: (context, snapshot) {
                  final players = snapshot.data ?? [];
                  if (players.isEmpty) {
                    return Center(
                      child: Text(
                        'No players connected yet.',
                        style: TextStyle(color: AppColors.textColorDark),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final p = players[index];
                      return Card(
                        color: AppColors.cardColor,
                        child: ListTile(
                          title: Text(
                            p['name'] ?? 'Unknown',
                            style: TextStyle(color: AppColors.textColorLight),
                          ),
                          subtitle: Text(
                            'Stats: ${p['stats'] ?? 'N/A'}',
                            style: TextStyle(color: AppColors.textColorDark),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
