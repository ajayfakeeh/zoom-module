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
    
    try {
      InitConfig initConfig = InitConfig(domain: "zoom.us", enableLog: true);
      String result = await zoom.initSdk(initConfig);
      print("SDK Init result: $result");
      
      if (result != "Success" && result != "SDK is already initialized.") {
        throw Exception("Zoom SDK init failed: $result");
      }
    } catch (e) {
      print("SDK initialization error: $e");
      // Continue anyway - SDK might already be initialized
    }
    
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
