import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zoom_module/zoom_integration/chat_sheet.dart';
import 'package:zoom_module/zoom_integration/utils/chat_manager.dart';
import 'package:zoom_module/zoom_integration/widgets/circle_icon_button.dart';

class ControlBar extends StatefulWidget {
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final VoidCallback onLeaveSession;
  final Function(bool, bool, bool) onStateUpdate;
  final ZoomVideoSdk zoom; // Add this

  const ControlBar({
    super.key,
    required this.isMuted,
    required this.isVideoOn,
    required this.isScreenSharing,
    required this.onLeaveSession,
    required this.onStateUpdate,
    required this.zoom, // Add this
  });

  @override
  State<ControlBar> createState() => _ControlBarState();
}

class _ControlBarState extends State<ControlBar> {
  late ZoomVideoSdk zoom; // ✅ Use late keyword
  late bool currentMuted;
  late bool currentVideoOn;
  late bool currentScreenSharing;
  int unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    zoom = widget.zoom;
    currentMuted = widget.isMuted;
    currentVideoOn = widget.isVideoOn;
    currentScreenSharing = widget.isScreenSharing;
    ChatManager().setMessageCallback(() {
      if (mounted) {
        setState(() {
          unreadMessages = ChatManager().unreadCount;
        });
      }
    });
  }

  /*@override
  void didUpdateWidget(ControlBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    currentMuted = widget.isMuted;
    currentVideoOn = widget.isVideoOn;
    currentScreenSharing = widget.isScreenSharing;
  }*/

  Future toggleAudio() async {
    final mySelf = await zoom.session.getMySelf();
    if (mySelf?.audioStatus == null) return;
    final isMuted = await mySelf!.audioStatus!.isMuted();
    if (isMuted) {
      await zoom.audioHelper.unMuteAudio(mySelf.userId);
    } else {
      await zoom.audioHelper.muteAudio(mySelf.userId);
    }
    final newMuted = !isMuted;
    setState(() {
      currentMuted = newMuted;
    });
    widget.onStateUpdate(newMuted, currentVideoOn, currentScreenSharing);
  }

  Future toggleVideo() async {
    final mySelf = await zoom.session.getMySelf();
    if (mySelf?.videoStatus == null) return;
    final isOn = await mySelf!.videoStatus!.isOn();
    if (isOn) {
      await zoom.videoHelper.stopVideo();
    } else {
      await zoom.videoHelper.startVideo();
    }
    final newVideoOn = !isOn;
    setState(() {
      currentVideoOn = newVideoOn;
    });
    widget.onStateUpdate(currentMuted, newVideoOn, currentScreenSharing);
  }

  Future switchCamera() async {
    try {
      // Pass null to switch to next available camera (front/back)
      bool success = await zoom.videoHelper.switchCamera(null);
      debugPrint('Camera switch success: $success');
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  Future<void> requestPermissions() async {
    final microphone = await Permission.microphone.request();
    final overlay = await Permission.systemAlertWindow.request();

    if (!microphone.isGranted || !overlay.isGranted) {
      debugPrint('❌ Required permissions not granted');
      return;
    }
  }

  Future toggleScreenShare() async {
    try {
      if (currentScreenSharing) {
        String? result = await zoom.shareHelper.stopShare();
        debugPrint('Stop screen share result: ${result ?? "Success"}');
      } else {
        await requestPermissions();
        await zoom.shareHelper.shareScreen();
        debugPrint('Screen share started');
      }
      setState(() {
        currentScreenSharing = !currentScreenSharing;
      });
    } catch (e) {
      debugPrint('Error toggling screen share: $e');
    }
  }

  Future leaveSession() async {
    await zoom.leaveSession(false);
    if (mounted) {
      Navigator.of(context).pop(); // Pops current screen
    }
    widget.onLeaveSession();
  }

  @override
  Widget build(BuildContext context) {
    // final double circleButtonSize = 28.0; // icon size inside the circle
    // final double circleButtonPadding =
    //     16.0; // padding around the icon for circle size

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding:
            EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final spacing = isTablet ? 12.0 : 6.0;

            // List of buttons wrapped in widgets to set size, padding, tooltip etc.
            final buttons = [
              // Chat button with badge
              Stack(
                children: [
                  CircleIconButton(
                    icon: Icons.chat,
                    iconColor: Colors.blue,
                    backgroundColor: Colors.white,
                    tooltip: "Chat",
                    onPressed: () {
                      ChatManager().clearUnreadCount();
                      setState(() {
                        unreadMessages = 0;
                      });
                      showModalBottomSheet(
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => ChatSheet(zoom: zoom),
                      );
                    },
                  ),
                  if (unreadMessages > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          unreadMessages > 99
                              ? '99+'
                              : unreadMessages.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              CircleIconButton(
                icon: currentMuted ? Icons.mic_off : Icons.mic,
                iconColor: Colors.blue,
                backgroundColor: Colors.white,
                tooltip: currentMuted ? "Unmute" : "Mute",
                onPressed: toggleAudio,
              ),
              CircleIconButton(
                icon: currentVideoOn ? Icons.videocam : Icons.videocam_off,
                iconColor: Colors.blue,
                backgroundColor: Colors.white,
                tooltip: currentVideoOn ? "Turn Video Off" : "Turn Video On",
                onPressed: toggleVideo,
              ),
              CircleIconButton(
                icon: Icons.flip_camera_ios,
                iconColor: Colors.blue,
                backgroundColor: Colors.white,
                tooltip: "Switch Camera",
                onPressed: switchCamera,
              ),
              CircleIconButton(
                icon: currentScreenSharing
                    ? Icons.stop_screen_share
                    : Icons.screen_share,
                iconColor: currentScreenSharing ? Colors.red : Colors.blue,
                backgroundColor: Colors.white,
                tooltip: currentScreenSharing ? "Stop Sharing" : "Share Screen",
                onPressed: toggleScreenShare,
              ),
              CircleIconButton(
                icon: Icons.call_end,
                iconColor: Colors.white,
                backgroundColor: Colors.red,
                tooltip: "Leave Call",
                onPressed: leaveSession,
              ),
            ];

            if (isTablet) {
              // Tablet: Scrollable horizontal row with spacing
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: buttons
                      .map((btn) => Padding(
                            padding: EdgeInsets.only(right: spacing),
                            child: btn,
                          ))
                      .toList(),
                ),
              );
            } else {
              // Mobile: Expanded buttons inside a Row to fill width evenly
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: buttons
                    .map((btn) => Expanded(
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: spacing / 2),
                            child: btn,
                          ),
                        ))
                    .toList(),
              );
            }
          },
        ),
      ),
    );
  }
}
