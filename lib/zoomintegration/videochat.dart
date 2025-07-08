import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:flutter_zoom_videosdk/flutter_zoom_view.dart' as zoom_view;
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_event_listener.dart';
import 'package:zoom_module/zoomintegration/utils/jwt.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';

import 'ChatSheet.dart';
import 'config.dart';

class Videochat extends StatefulWidget {
  final String appKey;
  final String appSecret;
  final Map<String, String> sessionDetails;

  const Videochat({
    super.key,
    required this.appKey,
    required this.appSecret,
    required this.sessionDetails,
  });

  @override
  State<Videochat> createState() => _VideochatState();
}

class _VideochatState extends State<Videochat> {
  final zoom = ZoomVideoSdk();
  final eventListener = ZoomVideoSdkEventListener();
  bool isInSession = false;
  List<StreamSubscription> subscriptions = [];
  List<ZoomVideoSdkUser> users = [];
  String? activeSpeakerId;
  bool isMuted = true;
  bool isVideoOn = false;
  bool isLoading = false;
  bool isScreenSharing = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _checkPermissions();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    handleLeaveSession();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    debugPrint('Camera permission: $camera, Microphone permission: $mic');
  }

  _handleSessionJoin(data) async {
    if (!mounted) return;
    final mySelf = ZoomVideoSdkUser.fromJson(jsonDecode(data['sessionUser']));
    final remoteUsers = await zoom.session.getRemoteUsers() ?? [];
    final isMutedState = await mySelf.audioStatus?.isMuted() ?? true;
    final isVideoOnState = await mySelf.videoStatus?.isOn() ?? false;
    WakelockPlus.enable();
    
    setState(() {
      isInSession = true;
      isLoading = false;
      isMuted = isMutedState;
      isVideoOn = isVideoOnState;
      users = [mySelf, ...remoteUsers];
    });
  }

  _handleSessionLeave(data) async {
    debugPrint('Session left: $data');
    handleLeaveSession();
  }

  _updateUserList(data) async {
    final mySelf = await zoom.session.getMySelf();
    if (mySelf == null) return;
    final remoteUserList = await zoom.session.getRemoteUsers() ?? [];
    remoteUserList.insert(0, mySelf);
    setState(() {
      users = remoteUserList;
    });
  }

  _handleVideoChange(data) async {
    if (!mounted) return;
    final mySelf = await zoom.session.getMySelf();
    final videoStatus = await mySelf?.videoStatus?.isOn() ?? false;
    setState(() {
      isVideoOn = videoStatus;
      // Force rebuild of video tiles to update camera status
      users = List.from(users);
    });
  }

  _handleAudioChange(data) async {
    if (!mounted) return;
    final mySelf = await zoom.session.getMySelf();
    final audioStatus = await mySelf?.audioStatus?.isMuted() ?? true;
    setState(() {
      isMuted = audioStatus;
    });
  }

  _handleActiveSpeakerChange(data) {
    debugPrint('Active speaker changed: ${data['userId']}');
    setState(() {
      activeSpeakerId = data['userId'];
    });
  }

  _handleShareChange(data) {
    debugPrint('Share status changed: $data');
    setState(() {
      isScreenSharing = data['isSharing'] ?? false;
    });
  }

  _setupEventListeners() {
    subscriptions = [
      eventListener.addListener(EventType.onSessionJoin, _handleSessionJoin),
      eventListener.addListener(EventType.onSessionLeave, _handleSessionLeave),
      eventListener.addListener(EventType.onUserJoin, _updateUserList),
      eventListener.addListener(EventType.onUserLeave, _updateUserList),
      eventListener.addListener(EventType.onUserVideoStatusChanged, _handleVideoChange),
      eventListener.addListener(EventType.onUserAudioStatusChanged, _handleAudioChange),
      eventListener.addListener(EventType.onUserActiveAudioChanged, _handleActiveSpeakerChange),
      eventListener.addListener(EventType.onShareContentChanged, _handleShareChange),
    ];
  }

  Future startSession() async {
    if (isLoading || isInSession) return;
    
    setState(() => isLoading = true);
    
    try {
      // Clear any existing subscriptions before setting up new ones
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
      subscriptions.clear();
      
      final token = generateJwt(
        sessionDetails['sessionName'],
        sessionDetails['roleType'],
        widget.appKey,
        widget.appSecret,
      );
      
      _setupEventListeners();
      
      await zoom.joinSession(
        JoinSessionConfig(
          sessionName: sessionDetails['sessionName']!,
          sessionPassword: sessionDetails['sessionPassword']!,
          token: token,
          userName: sessionDetails['displayName']!,
          audioOptions: {"connect": true, "mute": true},
          videoOptions: {"localVideoOn": true},
          sessionIdleTimeoutMins: int.parse(sessionDetails['sessionTimeout']!),
        ),
      );
    } catch (e) {
      debugPrint("Error starting session: $e");
      setState(() => isLoading = false);
    }
  }

  handleLeaveSession([data]) async {
    debugPrint('handleLeaveSession called');
    WakelockPlus.disable();
    
    // Clear all subscriptions first
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
    subscriptions.clear();
    
    if (isInSession) {
      try {
        await zoom.leaveSession(false);
      } catch (e) {
        debugPrint('Error leaving session: $e');
      }
    }
    
    // Reset all state variables
    if (mounted) {
      setState(() {
        isInSession = false;
        isLoading = false;
        users = [];
        activeSpeakerId = null;
        isMuted = true;
        isVideoOn = false;
        isScreenSharing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Stack(
          children: [
            if (!isInSession)
              Center(
                child: isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Connecting to session...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: startSession,
                        child: Text('Start Session'),
                      ),
              )
            else
              Stack(
                children: [
                  VideoGrid(
                    key: ValueKey(users.length),
                    users: users, 
                    activeSpeakerId: activeSpeakerId,
                    onSpeakerChange: (userId) {
                      setState(() {
                        activeSpeakerId = userId;
                      });
                    },
                  ),
                  ControlBar(
                    isMuted: isMuted,
                    isVideoOn: isVideoOn,
                    isScreenSharing: isScreenSharing,
                    onLeaveSession: handleLeaveSession,
                  ),
                  if (isInSession && users.isEmpty)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Loading video...',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class VideoGrid extends StatelessWidget {
  final List<ZoomVideoSdkUser> users;
  final String? activeSpeakerId;
  final Function(String) onSpeakerChange;

  const VideoGrid({
    super.key, 
    required this.users, 
    this.activeSpeakerId,
    required this.onSpeakerChange,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Find active speaker - prioritize actual active speaker, then first user
    ZoomVideoSdkUser activeSpeaker;
    if (activeSpeakerId != null) {
      try {
        activeSpeaker = users.firstWhere((user) => user.userId == activeSpeakerId);
      } catch (e) {
        // If active speaker not found, use first user
        activeSpeaker = users.first;
      }
    } else {
      // No active speaker set, use first user
      activeSpeaker = users.first;
    }
    
    debugPrint('Active speaker: ${activeSpeaker.userId}, Total users: ${users.length}');
    
    final otherUsers = users.where((user) => user.userId != activeSpeaker.userId).toList();

    return Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox(
          height: screenHeight,
          width: screenWidth,
          child: Stack(
            children: [
              // Fullscreen active speaker
              Positioned.fill(
                child: _VideoTile(user: activeSpeaker, isMainView: true),
              ),

              // ✅ Top-left user name overlay
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activeSpeaker.userName ?? "Unknown",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Small user tiles in top-right corner
              if (otherUsers.isNotEmpty)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: otherUsers.asMap().entries.map((entry) {
                      ZoomVideoSdkUser user = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        width: 90,
                        height: 120,
                        child: GestureDetector(
                          onTap: () {
                            debugPrint('Manually switching to user: ${user.userId}');
                            onSpeakerChange(user.userId);
                          },
                          child: _VideoTile(user: user, isMainView: false),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final ZoomVideoSdkUser user;
  final bool isMainView;

  const _VideoTile({required this.user, this.isMainView = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: isMainView ? null : BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: isMainView ? BorderRadius.zero : BorderRadius.circular(8),
        child: SizedBox.expand(
          child: FutureBuilder<bool>(
            key: Key('${user.userId}_${DateTime.now().millisecondsSinceEpoch}'),
            future: user.videoStatus?.isOn(),
            builder: (context, snapshot) {
              final isVideoOn = snapshot.data ?? false;
              
              if (!isVideoOn) {
                return Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: isMainView ? 80 : 40,
                          color: Colors.white70,
                        ),
                        SizedBox(height: 8),
                        Text(
                          user.userName ?? "Unknown",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMainView ? 18 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return zoom_view.View(
                key: Key('${user.userId}_video'),
                creationParams: {
                  "userId": user.userId,
                  "videoAspect": VideoAspect.FullFilled,
                  "fullScreen": false,
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class ControlBar extends StatefulWidget {
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final VoidCallback onLeaveSession;

  const ControlBar({
    super.key,
    required this.isMuted,
    required this.isVideoOn,
    required this.isScreenSharing,
    required this.onLeaveSession,
  });

  @override
  State<ControlBar> createState() => _ControlBarState();
}

class _ControlBarState extends State<ControlBar> {
  final zoom = ZoomVideoSdk();
  late bool currentMuted;
  late bool currentVideoOn;
  late bool currentScreenSharing;

  @override
  void initState() {
    super.initState();
    currentMuted = widget.isMuted;
    currentVideoOn = widget.isVideoOn;
    currentScreenSharing = widget.isScreenSharing;
  }

  @override
  void didUpdateWidget(ControlBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    currentMuted = widget.isMuted;
    currentVideoOn = widget.isVideoOn;
    currentScreenSharing = widget.isScreenSharing;
  }

  Future toggleAudio() async {
    final mySelf = await zoom.session.getMySelf();
    if (mySelf?.audioStatus == null) return;
    final isMuted = await mySelf!.audioStatus!.isMuted();
    if (isMuted) {
      await zoom.audioHelper.unMuteAudio(mySelf.userId);
    } else {
      await zoom.audioHelper.muteAudio(mySelf.userId);
    }
    setState(() {
      currentMuted = !isMuted;
    });
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
    setState(() {
      currentVideoOn = !isOn;
    });
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

  Future toggleScreenShare() async {
    try {
      if (currentScreenSharing) {
        String? result = await zoom.shareHelper.stopShare();
        debugPrint('Stop screen share result: ${result ?? "Success"}');
      } else {
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
    widget.onLeaveSession();
  }

  @override
  Widget build(BuildContext context) {

    final double circleButtonSize = 28.0; // icon size inside the circle
    final double circleButtonPadding = 16.0; // padding around the icon for circle size

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircleIconButton(
              icon: Icons.chat,
              iconColor: Colors.blue,
              tooltip: "Chat",
              onPressed: () {
                showModalBottomSheet(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const ChatSheet(),
                ).then((_) {
                  // Force video tiles refresh
                  setState(() {
                    users = List.from(users);
                  });
                });
              },
            ),
            _buildCircleIconButton(
              icon: currentMuted ? Icons.mic_off : Icons.mic,
              iconColor: Colors.blue,
              tooltip: currentMuted ? "Unmute" : "Mute",
              onPressed: toggleAudio,
            ),
            _buildCircleIconButton(
              icon: currentVideoOn ? Icons.videocam : Icons.videocam_off,
              iconColor: Colors.blue,
              tooltip: currentVideoOn ? "Turn Video Off" : "Turn Video On",
              onPressed: toggleVideo,
            ),
            _buildCircleIconButton(
              icon: Icons.flip_camera_ios,
              iconColor: Colors.blue,
              tooltip: "Switch Camera",
              onPressed: switchCamera,
            ),
            _buildCircleIconButton(
              icon: currentScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              iconColor: currentScreenSharing ? Colors.red : Colors.blue,
              tooltip: currentScreenSharing ? "Stop Sharing" : "Share Screen",
              onPressed: toggleScreenShare,
            ),
            _buildCircleRedButton(
              icon: Icons.call_end,
              iconColor: Colors.white,
              tooltip: "Leave Call",
              onPressed: leaveSession,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black45,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 28.0 + 16.0,
            height: 28.0 + 16.0,
            alignment: Alignment.center,
            child: Tooltip(
              message: tooltip ?? '',
              child: Icon(
                icon,
                size: 28.0,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleRedButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.red,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black45,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 28.0 + 16.0,
            height: 28.0 + 16.0,
            alignment: Alignment.center,
            child: Tooltip(
              message: tooltip ?? '',
              child: Icon(
                icon,
                size: 28.0,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}