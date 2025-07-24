import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zoom_module/zoom_integration/chat_sheet.dart';
import 'package:zoom_module/zoom_integration/participants_screen.dart';
import 'package:zoom_module/zoom_integration/utils/chat_manager.dart';

class FooterButtonWidget extends StatefulWidget {
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final VoidCallback onLeaveSession;
  final Function(bool, bool, bool) onStateUpdate;
  final ZoomVideoSdk zoom;
  final List<ZoomVideoSdkUser> users;

  const FooterButtonWidget({
    super.key,
    required this.isMuted,
    required this.isVideoOn,
    required this.isScreenSharing,
    required this.onLeaveSession,
    required this.onStateUpdate,
    required this.zoom,
    required this.users,
  });

  @override
  State<FooterButtonWidget> createState() => _FooterButtonWidgetState();
}

class _FooterButtonWidgetState extends State<FooterButtonWidget> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: footerButton(
              icon: currentMuted ? Icons.mic_off : Icons.mic,
              text: currentMuted ? "Unmute" : "Mute",
              onTap: toggleAudio,
            ),
          ),
          Expanded(
            child: footerButton(
              icon: currentVideoOn ? Icons.videocam : Icons.videocam_off,
              text: currentVideoOn ? "Stop Video" : "Start Video",
              onTap: toggleVideo,
            ),
          ),
          Expanded(
            child: footerButton(
              icon: Icons.chat,
              text: "Chat",
              onTap: () {
                // Reset unread count when chat is opened
                ChatManager().clearUnreadCount();
                setState(() {
                  unreadMessages = 0;
                });
                showModalBottomSheet(
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => ChatSheet(zoom: zoom),
                );
              },
              showNotification: unreadMessages > 0,
            ),
          ),
          Expanded(
            child: footerButton(
              icon: Icons.people_sharp,
              text: "Participants",
              onTap: () {
                showModalBottomSheet(
                  backgroundColor: Colors.black,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  context: context,
                  isScrollControlled: true,
                  builder: (context) =>
                      ParticipantsScreen(participants: widget.users),
                );
              },
            ),
          ),
          // Expanded(
          //   child: footerButton(
          //     icon: Icons.screen_share,
          //     text: "Share Screen",
          //     onTap: toggleScreenShare,
          //   ),
          // ),
          Expanded(
            child: footerButton(
              icon: Icons.call_end,
              text: "Leave",
              onTap: widget.onLeaveSession,
              buttonColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget footerButton(
      {required IconData icon,
      required String text,
      required VoidCallback onTap,
      bool showNotification = false,
      Color buttonColor = Colors.white}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    double aspectRatio = screenWidth / screenHeight;

    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            color: buttonColor,
            size: aspectRatio > .5 ? 32 : 24,
          ),
          if (showNotification)
            Positioned(
              right: 0,
              top: -5, // Adjust to prevent overlap with button edge
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  unreadMessages > 99 ? '99+' : unreadMessages.toString(),
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
    );
  }

  // Existing toggle functions
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

  Future requestPermissions() async {
    final microphone = await Permission.microphone.request();
    final overlay = await Permission.systemAlertWindow.request();

    if (!microphone.isGranted || !overlay.isGranted) {
      debugPrint('❌ Required permissions not granted');
      return;
    }
  }
}
