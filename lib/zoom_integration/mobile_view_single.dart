import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:zoom_module/zoom_integration/widgets/floating_user_widget.dart';
import 'package:zoom_module/zoom_integration/mobile_view_multiple.dart';
import 'package:zoom_module/zoom_integration/widgets/footer_button_widget.dart';
import 'package:zoom_module/zoom_integration/widgets/video_widget.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';

class MobileViewSingle extends StatefulWidget {
  final List<ZoomVideoSdkUser> users;
  final String? activeSpeakerId;
  final Function(String) onSpeakerChange;
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final VoidCallback onLeaveSession;
  final Function(bool, bool, bool) onStateUpdate;
  final ZoomVideoSdk zoom;

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
    required this.zoom,
  });

  @override
  State<MobileViewSingle> createState() => _MobileViewSingleState();
}

class _MobileViewSingleState extends State<MobileViewSingle> {
  ZoomVideoSdkUser? activeSpeaker;
  bool _isManualSpeakerChange = false;
  String? localUserId;

  @override
  void initState() {
    super.initState();
    findActiveSpeaker();
    identifyLocalUser();
  }

  Future<void> identifyLocalUser() async {
    final self = await widget.zoom.session.getMySelf();
    if (self != null) {
      setState(() {
        localUserId = self.userId;
      });
    }
  }

  @override
  void didUpdateWidget(covariant MobileViewSingle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isManualSpeakerChange) return;

    if (oldWidget.users != widget.users ||
        oldWidget.activeSpeakerId != widget.activeSpeakerId) {
      findActiveSpeaker();
    }
  }

  void findActiveSpeaker() {
    ZoomVideoSdkUser? newActiveSpeaker;

    if (widget.users.length == 2) {
      newActiveSpeaker = widget.users[1]; // Remote user
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
        'Active speaker: ${activeSpeaker?.userId}, Total users: ${widget.users.length}');
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

  Future switchCamera() async {
    try {
      // Pass null to switch to next available camera (front/back)
      bool success = await widget.zoom.videoHelper.switchCamera(null);
      debugPrint('Camera switch success: $success');
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.users.length > 2) {
      return MobileViewMultiple(
        users: widget.users,
        localUserId: localUserId ?? "",
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
      // appBar: ZoomAppBar(leaveSession: widget.onLeaveSession),
      body: Column(
        children: [
          if (activeSpeaker != null)
            Expanded(
              child: Stack(
                children: [
                  VideoWidget(
                    user: activeSpeaker!,
                    isMainView: true,
                    onCameraFlip: switchCamera,
                    isLocalUser: activeSpeaker!.userId == localUserId,
                  ),
                  if (otherUsers.isNotEmpty)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingUserWidget(
                        otherUsers: otherUsers,
                        onTap: _handleManualSwitch,
                        switchCamera: switchCamera,
                        localUserId: localUserId ?? "",
                      ),
                    ),
                ],
              ),
            ),
          FooterButtonWidget(
            isMuted: widget.isMuted,
            isVideoOn: widget.isVideoOn,
            isScreenSharing: widget.isScreenSharing,
            onLeaveSession: widget.onLeaveSession,
            zoom: widget.zoom,
            onStateUpdate: widget.onStateUpdate,
            users: widget.users,
          ),
        ],
      ),
    );
  }
}
