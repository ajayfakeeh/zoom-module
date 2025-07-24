import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';

class ParticipantsScreen extends StatelessWidget {
  final List<ZoomVideoSdkUser> participants;

  const ParticipantsScreen({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.95,
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
        color: Colors.black,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Participants",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      child: Text(
                        participant.userName.isNotEmpty
                            ? participant.userName.substring(0, 1)
                            : "U",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      participant.userName,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: participant.isHost
                        ? Text(
                            "Host",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    trailing: FutureBuilder<bool>(
                      future: _getMuteStatus(
                          participant), // Future to get mute status
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator(); // Show loading until the result is ready
                        }

                        if (snapshot.hasError) {
                          return Icon(Icons.error, color: Colors.red);
                        }

                        final isMuted = snapshot.data ?? true;

                        return Icon(
                          isMuted ? Icons.mic_off : Icons.mic,
                          color: isMuted ? Colors.red : Colors.green,
                        );
                      },
                    ),
                    tileColor: Colors.black26,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to fetch mute status (async)
  Future<bool> _getMuteStatus(ZoomVideoSdkUser participant) async {
    if (participant.audioStatus == null) {
      return true; // Default to muted if no audio status is available
    }
    return await participant.audioStatus!.isMuted();
  }
}
