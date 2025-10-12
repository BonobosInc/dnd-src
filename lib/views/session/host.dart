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
          onPressed: () async {
            await widget.server.stop();
            Navigator.pop(context);
          },
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
                // assuming your server exposes a player stream
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
