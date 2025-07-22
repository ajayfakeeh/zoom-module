import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:zoom_module/zoom_integration/tab_view_multiple.dart';
import 'package:zoom_module/zoom_integration/widgets/control_bar.dart';
import 'package:zoom_module/zoom_integration/widgets/floating_user_widget.dart';
import 'package:zoom_module/zoom_integration/widgets/user_name_bottom.dart';
import 'package:zoom_module/zoom_integration/widgets/video_widget.dart';

class TabViewSingle extends StatefulWidget {
  final List<ZoomVideoSdkUser> users;
  final String? activeSpeakerId;
  final Function(String) onSpeakerChange;
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final VoidCallback onLeaveSession;
  final Function(bool, bool, bool) onStateUpdate;
  final ZoomVideoSdk zoom;

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
  bool _isManualSpeakerChange = false;

  @override
  void initState() {
    super.initState();
    findActiveSpeaker();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
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

    // Skip auto speaker update if user changed it manually
    if (_isManualSpeakerChange) return;

    if (oldWidget.users != widget.users ||
        oldWidget.activeSpeakerId != widget.activeSpeakerId) {
      findActiveSpeaker();
    }
  }

  void findActiveSpeaker() {
    ZoomVideoSdkUser? newActiveSpeaker;

    if (widget.users.length == 2) {
      newActiveSpeaker = widget.users[1];
    } else if (widget.activeSpeakerId != null) {
      try {
        newActiveSpeaker = widget.users
            .firstWhere((user) => user.userId == widget.activeSpeakerId);
      } catch (_) {
        newActiveSpeaker = widget.users.first;
      }
    } else {
      newActiveSpeaker = widget.users.first;
    }

    if (newActiveSpeaker.userId != activeSpeaker?.userId) {
      setState(() {
        activeSpeaker = newActiveSpeaker;
      });
    }

    debugPrint(
        'Active speaker updated: ${activeSpeaker?.userId}, Total users: ${widget.users.length}');
  }

  void _handleManualSwitch(ZoomVideoSdkUser user) {
    setState(() {
      _isManualSpeakerChange = true;
      widget.onSpeakerChange(user.userId);
      activeSpeaker = user;

      // Optional: reset manual override after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _isManualSpeakerChange = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
                  onTap: _handleManualSwitch,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
