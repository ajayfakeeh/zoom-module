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
      eventListener.addListener(EventType.onSessionLeave, handleLeaveSession),
      eventListener.addListener(EventType.onUserJoin, _updateUserList),
      eventListener.addListener(EventType.onUserLeave, _updateUserList),
      eventListener.addListener(EventType.onUserVideoStatusChanged, _handleVideoChange),
      eventListener.addListener(EventType.onUserAudioStatusChanged, _handleAudioChange),
      eventListener.addListener(EventType.onUserActiveAudioChanged, _handleActiveSpeakerChange),
      eventListener.addListener(EventType.onShareContentChanged, _handleShareChange),
    ];
  }

  Future startSession() async {
    setState(() => isLoading = true);
    try {
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
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  handleLeaveSession([data]) async {
    WakelockPlus.disable();
    
    if (isInSession) {
      try {
        await zoom.leaveSession(false);
      } catch (e) {
        debugPrint('Error leaving session: $e');
      }
    }
    
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
    subscriptions.clear();
    
    if (mounted) {
      setState(() {
        isInSession = false;
        isLoading = false;
        users = [];
        activeSpeakerId = null;
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
                child: ElevatedButton(
                  onPressed: isLoading ? null : startSession,
                  child: Text(isLoading ? 'Connecting...' : 'Start Session'),
                ),
              )
            else
              Stack(
                children: [
                  VideoGrid(
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
    
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: otherUsers.isNotEmpty ? 8 : 0),
            child: _VideoTile(user: activeSpeaker, isMainView: true),
          ),
        ),
        if (otherUsers.isNotEmpty)
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: otherUsers.length,
              itemBuilder: (context, index) => Container(
                width: 90,
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    // Manually set this user as active speaker when tapped
                    debugPrint('Manually switching to user: ${otherUsers[index].userId}');
                    onSpeakerChange(otherUsers[index].userId);
                  },
                  child: _VideoTile(user: otherUsers[index], isMainView: false),
                ),
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
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
          child: zoom_view.View(
            key: Key(user.userId),
            creationParams: {
              "userId": user.userId,
              "videoAspect": VideoAspect.FullFilled,
              "fullScreen": false,
            },
          ),
        ),
      ),
    );
  }
}

class ControlBar extends StatelessWidget {
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final double circleButtonSize = 40.0;
  final zoom = ZoomVideoSdk();
  final VoidCallback onLeaveSession;

  ControlBar({
    super.key,
    required this.isMuted,
    required this.isVideoOn,
    required this.isScreenSharing,
    required this.onLeaveSession,
  });

  Future toggleAudio() async {
    final mySelf = await zoom.session.getMySelf();
    if (mySelf?.audioStatus == null) return;
    final isMuted = await mySelf!.audioStatus!.isMuted();
    isMuted
        ? await zoom.audioHelper.unMuteAudio(mySelf.userId)
        : await zoom.audioHelper.muteAudio(mySelf.userId);
  }

  Future toggleVideo() async {
    final mySelf = await zoom.session.getMySelf();
    if (mySelf?.videoStatus == null) return;
    final isOn = await mySelf!.videoStatus!.isOn();
    isOn
        ? await zoom.videoHelper.stopVideo()
        : await zoom.videoHelper.startVideo();
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
      if (isScreenSharing) {
        String? result = await zoom.shareHelper.stopShare();
        debugPrint('Stop screen share result: ${result ?? "Success"}');
      } else {
        await zoom.shareHelper.shareScreen();
        debugPrint('Screen share started');
      }
    } catch (e) {
      debugPrint('Error toggling screen share: $e');
    }
  }

  Future leaveSession() async {
    await zoom.leaveSession(false);
    onLeaveSession();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: toggleAudio,
              icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
              iconSize: circleButtonSize,
              tooltip: isMuted ? "Unmute" : "Mute",
              color: Colors.white,
            ),
            IconButton(
              onPressed: toggleVideo,
              iconSize: circleButtonSize,
              icon: Icon(
                isVideoOn ? Icons.videocam : Icons.videocam_off,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: switchCamera,
              iconSize: circleButtonSize,
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              tooltip: "Switch Camera",
            ),
            IconButton(
              onPressed: toggleScreenShare,
              iconSize: circleButtonSize,
              icon: Icon(
                isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
                color: isScreenSharing ? Colors.red : Colors.white,
              ),
              tooltip: isScreenSharing ? "Stop Sharing" : "Share Screen",
            ),
            IconButton(
              onPressed: leaveSession,
              iconSize: circleButtonSize,
              icon: const Icon(Icons.call_end, color: Colors.red),
            ),
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const ChatSheet(),
                );
              },
              iconSize: circleButtonSize,
              icon: const Icon(Icons.chat, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}