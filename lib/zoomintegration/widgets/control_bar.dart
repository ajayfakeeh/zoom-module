import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zoom_module/zoomintegration/ChatManager.dart';
import 'package:zoom_module/zoomintegration/ChatSheet.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:zoom_module/zoomintegration/widgets/circle_icon_button.dart';

class ControlBar extends StatefulWidget {
  final bool isMuted, isVideoOn, isScreenSharing;
  final VoidCallback onLeaveSession;
  final Function(bool, bool, bool) onStateUpdate;
  final ZoomVideoSdk zoom;

  const ControlBar({
    super.key,
    required this.isMuted,
    required this.isVideoOn,
    required this.isScreenSharing,
    required this.onLeaveSession,
    required this.onStateUpdate,
    required this.zoom,
  });

  @override
  _ControlBarState createState() => _ControlBarState();
}

class _ControlBarState extends State<ControlBar> with WidgetsBindingObserver {
  late ZoomVideoSdk zoom;
  late bool currentMuted, currentVideoOn, currentScreenSharing;
  bool _videoToggleInProgress = false;
  bool _shareToggleInProgress = false;
  int unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    zoom = widget.zoom;
    currentMuted = widget.isMuted;
    currentVideoOn = widget.isVideoOn;
    currentScreenSharing = widget.isScreenSharing;
    ChatManager().setMessageCallback(_onChatUpdate);
  }

  void _onChatUpdate() {
    if (mounted) {
      setState(() => unreadMessages = ChatManager().unreadCount);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // ChatManager().clearMessageCallback();
    _stopAllVideoResources();
    super.dispose();
  }

  @override
  void didUpdateWidget(ControlBar old) {
    super.didUpdateWidget(old);
    if (widget.isMuted != old.isMuted ||
        widget.isVideoOn != old.isVideoOn ||
        widget.isScreenSharing != old.isScreenSharing) {
      setState(() {
        currentMuted = widget.isMuted;
        currentVideoOn = widget.isVideoOn;
        currentScreenSharing = widget.isScreenSharing;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopAllVideoResources();
    }
  }

  Future<void> _stopAllVideoResources() async {
    try { await zoom.videoHelper.stopVideo(); } catch (_) {}
    try { await zoom.shareHelper.stopShare(); } catch (_) {}
  }

  Future<void> _toggleAudio() async {
    final me = await zoom.session.getMySelf();
    if (me?.audioStatus == null) return;
    final muted = await me!.audioStatus!.isMuted();
    try {
      if (muted) await zoom.audioHelper.unMuteAudio(me.userId);
      else await zoom.audioHelper.muteAudio(me.userId);

      setState(() => currentMuted = !muted);
      widget.onStateUpdate(currentMuted, currentVideoOn, currentScreenSharing);
    } catch (e) {
      debugPrint('Audio toggle failed: $e');
    }
  }

  Future<void> _toggleVideo() async {
    if (_videoToggleInProgress) return;
    _videoToggleInProgress = true;

    try {
      final me = await zoom.session.getMySelf();
      if (me?.videoStatus == null) return;
      final isOn = await me!.videoStatus!.isOn();

      if (isOn) {
        await zoom.videoHelper.stopVideo();
      } else {
        final perm = await Permission.microphone.request();
        if (!perm.isGranted) return;
        await zoom.videoHelper.startVideo();
      }

      setState(() => currentVideoOn = !isOn);
      widget.onStateUpdate(currentMuted, currentVideoOn, currentScreenSharing);
    } catch (e) {
      debugPrint('Video toggle failed: $e');
    } finally {
      _videoToggleInProgress = false;
    }
  }

  Future<void> _switchCamera() async {
    try {
      final ok = await zoom.videoHelper.switchCamera(null);
      debugPrint('Camera switched: $ok');
    } catch (e) {
      debugPrint('Switch camera error: $e');
    }
  }

  Future<void> _toggleShare() async {
    if (_shareToggleInProgress) return;
    _shareToggleInProgress = true;

    try {
      if (currentScreenSharing) {
        await zoom.shareHelper.stopShare();
      } else {
        final mic = await Permission.microphone.request();
        final overlayGranted = await Permission.systemAlertWindow.isGranted;

        if (!mic.isGranted || !overlayGranted) {
          // Open overlay settings if not granted
          if (!overlayGranted) {
            await _promptOverlayPermission();
          }

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Microphone & overlay permissions required.'),
          ));
          return;
        }

        // Now safe to share screen
        await zoom.shareHelper.shareScreen().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception("Screen share request timed out");
          },
        );
      }

      setState(() => currentScreenSharing = !currentScreenSharing);
      widget.onStateUpdate(currentMuted, currentVideoOn, currentScreenSharing);
    } catch (e) {
      debugPrint('❌ Share toggle failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to share screen: $e")),
      );
    } finally {
      _shareToggleInProgress = false;
    }
  }

  Future<void> _promptOverlayPermission() async {
    final intent = AndroidIntent(
      action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
      data: 'package:your.package.name', // replace with your app's package name
    );
    await intent.launch();
  }


  Future<void> _leaveSession() async {
    await zoom.leaveSession(false);
    if (mounted) Navigator.of(context).pop();
    widget.onLeaveSession();
  }

  @override
  Widget build(BuildContext c) {
    final isTablet = MediaQuery.of(c).size.width >= 600;
    final spacing = isTablet ? 12.0 : 6.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.all(spacing * 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildChatButton(),
            _buildIconButton(
                currentMuted ? Icons.mic_off : Icons.mic,
                currentMuted ? 'Unmute' : 'Mute',
                _toggleAudio),
            _buildIconButton(
                currentVideoOn ? Icons.videocam : Icons.videocam_off,
                currentVideoOn ? 'Stop Video' : 'Start Video',
                _toggleVideo),
            _buildIconButton(
                Icons.flip_camera_ios, 'Switch Camera', _switchCamera),
            _buildIconButton(
                currentScreenSharing
                    ? Icons.stop_screen_share
                    : Icons.screen_share,
                currentScreenSharing ? 'Stop Share' : 'Share Screen',
                _toggleShare,
                color: currentScreenSharing ? Colors.red : Colors.blue),
            _buildIconButton(Icons.call_end, 'Leave Call', _leaveSession,
                backgroundColor: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton() => Stack(
    children: [
      _buildIconButton(Icons.chat, 'Chat', () {
        HapticFeedback.selectionClick();
        ChatManager().clearUnreadCount();
        setState(() => unreadMessages = 0);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => ChatSheet(zoom: zoom),
        );
      }),
      if (unreadMessages > 0)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.red, borderRadius: BorderRadius.circular(8)),
            constraints:
            const BoxConstraints(minWidth: 20, minHeight: 20),
            child: Text(
              unreadMessages > 99 ? '99+' : '$unreadMessages',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        )
    ],
  );

  Widget _buildIconButton(IconData icon, String label, VoidCallback onTap,
      {Color color = Colors.blue,
        Color backgroundColor = Colors.white}) =>
      Semantics(
        label: label,
        button: true,
        child: CircleIconButton(
          icon: icon,
          iconColor: color,
          backgroundColor: backgroundColor,
          tooltip: label,
          onPressed: () {
            HapticFeedback.selectionClick();
            onTap();
          },
        ),
      );
}
