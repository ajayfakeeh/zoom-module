import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_event_listener.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zoom_module/zoomintegration/ChatManager.dart';
import 'package:zoom_module/zoomintegration/mobile_view_single.dart';
import 'package:zoom_module/zoomintegration/tab_view_single.dart';
import 'package:zoom_module/zoomintegration/utils/jwt.dart';
import 'package:zoom_module/zoomintegration/widgets/loading_widget.dart';

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
  bool isLoading = false;

  List<ZoomVideoSdkUser> users = [];
  String? activeSpeakerId;
  bool isMuted = true;
  bool isVideoOn = false;
  bool isScreenSharing = false;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) _checkPermissions();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _leaveSession();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
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

  Future<void> _handleSessionJoin(dynamic data) async {
    if (!mounted) return;

    final mySelf = ZoomVideoSdkUser.fromJson(jsonDecode(data['sessionUser']));
    final remoteUsers = await zoom.session.getRemoteUsers() ?? [];
    final isMutedState = await mySelf.audioStatus?.isMuted() ?? true;
    final isVideoOnState = await mySelf.videoStatus?.isOn() ?? false;

    ChatManager().initialize(mySelf.userId);

    WakelockPlus.enable();

    setState(() {
      isInSession = true;
      isLoading = false;
      isMuted = isMutedState;
      isVideoOn = isVideoOnState;
      users = [mySelf, ...remoteUsers];
    });

    debugPrint("Session joined. Users: ${users.length}");
  }

  Future<void> _handleSessionLeave(dynamic data) async {
    debugPrint('Session left: $data');
    _leaveSession();
  }

  Future<void> _updateUserList(dynamic data) async {
    debugPrint('User join/leave event: $data');
    if (!mounted) return;

    final mySelf = await zoom.session.getMySelf();
    if (mySelf == null) return;

    final remoteUsers = await zoom.session.getRemoteUsers() ?? [];
    final allUsers = [mySelf, ...remoteUsers];

    ChatManager().dispose();

    setState(() {
      users = List<ZoomVideoSdkUser>.from(allUsers);
      debugPrint('Users updated in UI: ${users.length}');
    });
  }

  Future<void> _handleVideoChange(dynamic data) async {
    if (!mounted) return;

    final mySelf = await zoom.session.getMySelf();
    final videoOn = await mySelf?.videoStatus?.isOn() ?? false;
    final remoteUsers = await zoom.session.getRemoteUsers() ?? [];
    final allUsers = [mySelf!, ...remoteUsers];

    setState(() {
      isVideoOn = videoOn;
      users = List<ZoomVideoSdkUser>.from(allUsers);
    });
  }

  Future<void> _handleAudioChange(dynamic data) async {
    if (!mounted) return;

    final mySelf = await zoom.session.getMySelf();
    final muted = await mySelf?.audioStatus?.isMuted() ?? true;

    setState(() {
      isMuted = muted;
    });
  }

  void _handleActiveSpeakerChange(dynamic data) {
    if (!mounted) return;

    final String? userId = data['userId'] as String?;
    setState(() {
      activeSpeakerId = userId;
    });
  }

  void _handleShareChange(dynamic data) {
    if (!mounted) return;

    final bool sharing = data['isSharing'] ?? false;
    setState(() {
      isScreenSharing = sharing;
    });
  }

  Future<void> startSession() async {
    if (isLoading || isInSession) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Cancel existing listeners if any
      for (var sub in subscriptions) {
        sub.cancel();
      }
      subscriptions.clear();

      final token = generateJwt(
        widget.sessionDetails['sessionName']!,
        widget.sessionDetails['roleType']!,
        widget.appKey,
        widget.appSecret,
      );

      _setupEventListeners();

      await zoom.joinSession(
        JoinSessionConfig(
          sessionName: widget.sessionDetails['sessionName']!,
          sessionPassword: widget.sessionDetails['sessionPassword']!,
          token: token,
          userName: widget.sessionDetails['displayName']!,
          audioOptions: {"connect": true, "mute": true},
          videoOptions: {"localVideoOn": true},
          sessionIdleTimeoutMins:
              int.parse(widget.sessionDetails['sessionTimeout']!),
        ),
      );
    } catch (e) {
      debugPrint('Error joining session: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _leaveSession() async {
    WakelockPlus.disable();

    for (var sub in subscriptions) {
      sub.cancel();
    }
    subscriptions.clear();

    if (isInSession) {
      try {
        await zoom.leaveSession(false);
      } catch (e) {
        debugPrint('Error leaving session: $e');
      }
    }

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
                        onLeaveSession: _leaveSession,
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
                        onLeaveSession: _leaveSession,
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
