// lib/zoom_module/zoom_launcher.dart
import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';

import 'videochat.dart'; // Path to your Videochat widget

class ZoomLauncher {
  static Future<Widget> initializeAndGetVideoChatWidget({
    required String appKey,
    required String appSecret,
    required Map<String, String> sessionDetails,
  }) async {
    var zoom = ZoomVideoSdk();
    InitConfig initConfig = InitConfig(domain: "zoom.us", enableLog: true);

    String result = await zoom.initSdk(initConfig);
    print("result" + result);
    return Videochat(
      appKey: appKey,
      appSecret: appSecret,
      sessionDetails: sessionDetails,
    );
    // if (result == "Success") {
    //   return const Videochat();
    // } else {
    //   throw Exception("Zoom SDK init failed: $result");
    // }
  }
}
