import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_event_listener.dart';
import 'package:zoom_module/zoomintegration/tab_view_single.dart';
import 'package:zoom_module/zoomintegration/utils/jwt.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'package:zoom_module/zoomintegration/widgets/loading_widget.dart';
import 'package:zoom_module/zoomintegration/mobile_view_single.dart';
import 'ChatManager.dart';
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
  String? myUserId;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _checkPermissions();
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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

  Future<void> _handleSessionJoin(data) async {
    if (!mounted) return;
    final mySelf = ZoomVideoSdkUser.fromJson(jsonDecode(data['sessionUser']));
    final remoteUsers = await zoom.session.getRemoteUsers() ?? [];
    final isMutedState = await mySelf.audioStatus?.isMuted() ?? true;
    final isVideoOnState = await mySelf.videoStatus?.isOn() ?? false;
    myUserId = mySelf.userId;

    // Initialize chat manager
    ChatManager().initialize(mySelf.userId);

    WakelockPlus.enable();

    setState(() {
      isInSession = true;
      isLoading = false;
      isMuted = isMutedState;
      isVideoOn = isVideoOnState;
      users = [mySelf, ...remoteUsers];
    });
  }

  Future<void> _handleSessionLeave(data) async {
    debugPrint('Session left: $data');
    handleLeaveSession();
  }

  Future<void> _updateUserList(data) async {
    final mySelf = await zoom.session.getMySelf();
    if (mySelf == null) return;
    final remoteUserList = await zoom.session.getRemoteUsers() ?? [];
    remoteUserList.insert(0, mySelf);
    setState(() {
      users = remoteUserList;
    });
  }

  Future<void> _handleVideoChange(data) async {
    if (!mounted) return;
    final mySelf = await zoom.session.getMySelf();
    final videoStatus = await mySelf?.videoStatus?.isOn() ?? false;
    setState(() {
      isVideoOn = videoStatus;
      // Force rebuild of video tiles to update camera status
      users = List.from(users);
    });
  }

  Future<void> _handleAudioChange(data) async {
    if (!mounted) return;
    final mySelf = await zoom.session.getMySelf();
    final audioStatus = await mySelf?.audioStatus?.isMuted() ?? true;
    setState(() {
      isMuted = audioStatus;
    });
  }

  void _handleActiveSpeakerChange(data) {
    debugPrint('Active speaker changed: ${data['userId']}');
    setState(() {
      activeSpeakerId = data['userId'];
    });
  }

  void _handleShareChange(data) {
    debugPrint('Share status changed: $data');
    setState(() {
      isScreenSharing = data['isSharing'] ?? false;
    });
  }

  void _setupEventListeners() {
    subscriptions = [
      eventListener.addListener(EventType.onSessionJoin, _handleSessionJoin),
      eventListener.addListener(EventType.onSessionLeave, _handleSessionLeave),
      eventListener.addListener(EventType.onUserJoin, _updateUserList),
      eventListener.addListener(EventType.onUserLeave, _updateUserList),
      eventListener.addListener(
          EventType.onUserVideoStatusChanged, _handleVideoChange),
      eventListener.addListener(
          EventType.onUserAudioStatusChanged, _handleAudioChange),
      eventListener.addListener(
          EventType.onUserActiveAudioChanged, _handleActiveSpeakerChange),
      eventListener.addListener(
          EventType.onShareContentChanged, _handleShareChange),
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

  Future<void> handleLeaveSession([data]) async {
    debugPrint('handleLeaveSession called');
    WakelockPlus.disable();
    // Dispose chat manager
    ChatManager().dispose();
    // Clear all subscriptions first
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
    subscriptions.clear();

    if (isInSession) {
      try {
        await zoom.leaveSession(false);
        await Future.delayed(Duration(seconds: 2));
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    double aspectRatio = screenWidth / screenHeight;
    print("aspect ratio $aspectRatio");
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: isInSession == false
            ? isLoading
                ? LoadingWidget(text: 'Connecting to session...')
                : ElevatedButton(
                    onPressed: startSession,
                    child: Text('Start Session'),
                  )
            : isInSession && users.isEmpty
                ? LoadingWidget(text: 'Loading video...')
                : aspectRatio > .5
                    ? TabViewSingle(
                        users: users,
                        activeSpeakerId: activeSpeakerId,
                        onSpeakerChange: (userId) {
                          setState(() {
                            activeSpeakerId = userId;
                          });
                        },
                        isMuted: isMuted,
                        isVideoOn: isVideoOn,
                        isScreenSharing: isScreenSharing,
                        onLeaveSession: handleLeaveSession,
                        zoom: zoom,
                        onStateUpdate: (muted, video, screen) {
                          setState(() {
                            isMuted = muted;
                            isVideoOn = video;
                            isScreenSharing = screen;
                          });
                        },
                      )
                    : MobileViewSingle(
                        users: users,
                        activeSpeakerId: activeSpeakerId,
                        onSpeakerChange: (userId) {
                          setState(() {
                            activeSpeakerId = userId;
                          });
                        },
                        isMuted: isMuted,
                        isVideoOn: isVideoOn,
                        isScreenSharing: isScreenSharing,
                        onLeaveSession: handleLeaveSession,
                        zoom: zoom,
                        onStateUpdate: (muted, video, screen) {
                          setState(() {
                            isMuted = muted;
                            isVideoOn = video;
                            isScreenSharing = screen;
                          });
                        },
                      ),
      ),
    );
  }
}
