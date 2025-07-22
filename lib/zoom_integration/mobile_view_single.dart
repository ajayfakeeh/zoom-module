import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:zoom_module/zoom_integration/widgets/floating_user_widget.dart';
import 'package:zoom_module/zoom_integration/mobile_view_multiple.dart';
import 'package:zoom_module/zoom_integration/widgets/video_widget.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:zoom_module/zoom_integration/widgets/control_bar.dart';

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

  @override
  void initState() {
    super.initState();
    findActiveSpeaker();
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

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
          icon: const Icon(Icons.close, color: Colors.white),
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
                  onTap: _handleManualSwitch,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
