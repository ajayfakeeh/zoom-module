import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:zoom_module/zoomintegration/tab_view_multiple.dart';
import 'package:zoom_module/zoomintegration/widgets/control_bar.dart';
import 'package:zoom_module/zoomintegration/widgets/floating_user_widget.dart';
import 'package:zoom_module/zoomintegration/widgets/user_name_bottom.dart';
import 'package:zoom_module/zoomintegration/widgets/video_widget.dart';

class TabViewSingle extends StatefulWidget {
  final List<ZoomVideoSdkUser> users;
  final String? activeSpeakerId;
  final Function(String) onSpeakerChange;
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final VoidCallback onLeaveSession;
  final Function(bool, bool, bool) onStateUpdate;
  final ZoomVideoSdk zoom; // Add this
  const TabViewSingle({
    super.key,
    required this.users,
    this.activeSpeakerId,
    required this.onSpeakerChange,
    required this.isMuted,
    required this.isVideoOn,
    required this.isScreenSharing,
    required this.onLeaveSession,
    required this.onStateUpdate,
    required this.zoom,
  });

  @override
  State<TabViewSingle> createState() => _TabViewSingleState();
}

class _TabViewSingleState extends State<TabViewSingle> {
  ZoomVideoSdkUser? activeSpeaker;

  @override
  void initState() {
    super.initState();
    findActiveSpeaker();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant TabViewSingle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If users list or activeSpeakerId changed, update activeSpeaker
    if (oldWidget.users != widget.users ||
        oldWidget.activeSpeakerId != widget.activeSpeakerId) {
      findActiveSpeaker();
    }
  }

  void findActiveSpeaker() {
    ZoomVideoSdkUser? newActiveSpeaker;

    if (widget.users.length == 2) {
      // When exactly 2 users, show remote user in main view
      newActiveSpeaker = widget.users[1];
    } else if (widget.activeSpeakerId != null) {
      try {
        newActiveSpeaker = widget.users
            .firstWhere((user) => user.userId == widget.activeSpeakerId);
      } catch (e) {
        // If active speaker not found, fallback to first user
        newActiveSpeaker = widget.users.first;
      }
    } else {
      // No active speaker set, fallback to first user
      newActiveSpeaker = widget.users.first;
    }

    if (newActiveSpeaker?.userId != activeSpeaker?.userId) {
      setState(() {
        activeSpeaker = newActiveSpeaker;
      });
    }

    debugPrint(
        'Active speaker updated: ${activeSpeaker?.userId}, Total users: ${widget.users.length}');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // For more than 2 users, use multi-user grid view
    if (widget.users.length > 2) {
      return TabViewMultiple(
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
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            if (activeSpeaker != null)
              Positioned.fill(
                child: VideoWidget(user: activeSpeaker!, isMainView: true),
              ),
            UserNameBottom(
              userName: activeSpeaker?.userName ?? "",
              position: 16,
            ),
            ControlBar(
              isMuted: widget.isMuted,
              isVideoOn: widget.isVideoOn,
              isScreenSharing: widget.isScreenSharing,
              onLeaveSession: widget.onLeaveSession,
              zoom: widget.zoom,
              onStateUpdate: widget.onStateUpdate,
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
