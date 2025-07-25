import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';

class ParticipantsScreen extends StatelessWidget {
  final List<ZoomVideoSdkUser> participants;

  const ParticipantsScreen({super.key, required this.participants});

  static const double _tileHeight = 70; // Approximate height per user
  static const double _maxHeight = 500; // Max height in pixels

  @override
  Widget build(BuildContext context) {
    // Calculate total height based on number of participants + 100 for header
    final double calculatedHeight = (participants.length * _tileHeight) + 100;
    final double finalHeight =
        calculatedHeight > _maxHeight ? _maxHeight : calculatedHeight;

    return SafeArea(
      child: Container(
        height: finalHeight,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Participants(${participants.length})",
                style: const TextStyle(
                  fontSize: 22,
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
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      participant.userName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: participant.isHost
                        ? const Text(
                            "Host",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    trailing: FutureBuilder(
                      future: _getStatuses(participant),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Icon(Icons.error, color: Colors.red);
                        }

                        final isMuted = snapshot.data?['muted'] ?? true;
                        final isVideoOn = snapshot.data?['videoOn'] ?? false;

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMuted ? Icons.mic_off : Icons.mic,
                              color: isMuted ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isVideoOn ? Icons.videocam : Icons.videocam_off,
                              color: isVideoOn ? Colors.green : Colors.red,
                            ),
                          ],
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

  Future<Map<String, bool>> _getStatuses(ZoomVideoSdkUser participant) async {
    bool muted = true;
    bool videoOn = false;

    if (participant.audioStatus != null) {
      muted = await participant.audioStatus!.isMuted();
    }

    if (participant.videoStatus != null) {
      videoOn = await participant.videoStatus!.isOn();
    }

    return {
      'muted': muted,
      'videoOn': videoOn,
    };
  }
}
