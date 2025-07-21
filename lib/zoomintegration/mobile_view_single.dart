import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:zoom_module/zoomintegration/widgets/floating_user_widget.dart';
import 'package:zoom_module/zoomintegration/mobile_view_multiple.dart';
import 'package:zoom_module/zoomintegration/widgets/video_widget.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:zoom_module/zoomintegration/widgets/control_bar.dart';

class MobileViewSingle extends StatefulWidget {
  final List<ZoomVideoSdkUser> users;
  final String? activeSpeakerId;
  final Function(String) onSpeakerChange;
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final VoidCallback onLeaveSession;
  final Function(bool, bool, bool) onStateUpdate;
  final ZoomVideoSdk zoom; // Add this

  const MobileViewSingle({
    super.key,
    required this.users,
    this.activeSpeakerId,
    required this.onSpeakerChange,
    required this.isMuted,
    required this.isVideoOn,
    required this.isScreenSharing,
    required this.onLeaveSession,
    required this.onStateUpdate,
    required this.zoom, // Add this
  });

  @override
  State<MobileViewSingle> createState() => _MobileViewSingleState();
}

class _MobileViewSingleState extends State<MobileViewSingle> {
  ZoomVideoSdkUser? activeSpeaker;

  @override
  void initState() {
    findActiveSpeaker();
    super.initState();
  }

  void findActiveSpeaker() {
    // Find active speaker - special logic for 2 users

    if (widget.users.length == 2) {
      // When only 2 users, show remote user in main view
      activeSpeaker = widget.users[1]; // Second user is remote user
    } else if (widget.activeSpeakerId != null) {
      try {
        activeSpeaker = widget.users
            .firstWhere((user) => user.userId == widget.activeSpeakerId);
      } catch (e) {
        // If active speaker not found, use first user
        activeSpeaker = widget.users.first;
      }
    } else {
      // No active speaker set, use first user
      activeSpeaker = widget.users.first;
    }

    debugPrint(
        'Active speaker: ${activeSpeaker?.userId}, Total users: ${widget.users.length}');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // For more than 2 users, show grid layout
    if (widget.users.length > 2) {
      return MobileViewMultiple(
        users: widget.users,
        isMuted: widget.isMuted,
        isVideoOn: widget.isVideoOn,
        onLeaveSession: widget.onLeaveSession,
        isScreenSharing: widget.isScreenSharing,
        onStateUpdate: widget.onStateUpdate,
        zoom: widget.zoom,
      );
    }

    final otherUsers = widget.users
        .where((user) => user.userId != activeSpeaker?.userId)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: widget.onLeaveSession,
          icon: Icon(Icons.close, color: Colors.white),
        ),
        centerTitle: true,
        title: Text(
          activeSpeaker?.userName ?? "",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (activeSpeaker != null)
                  Expanded(
                    child: VideoWidget(
                      user: activeSpeaker!,
                      isMainView: true,
                    ),
                  ),
                ControlBar(
                  isMuted: widget.isMuted,
                  isVideoOn: widget.isVideoOn,
                  isScreenSharing: widget.isScreenSharing,
                  onLeaveSession: widget.onLeaveSession,
                  zoom: widget.zoom,
                  onStateUpdate: widget.onStateUpdate,
                ),
              ],
            ),
            if (otherUsers.isNotEmpty)
              Positioned(
                top: 16,
                right: 16,
                child: FloatingUserWidget(
                  otherUsers: otherUsers,
                  onTap: (user) {
                    debugPrint('Manually switching to user: ${user.userId}');
                    setState(() {
                      widget.onSpeakerChange(user.userId);
                      activeSpeaker = user;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
