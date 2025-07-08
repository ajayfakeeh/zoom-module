// lib/zoom_module/zoom_launcher.dart
import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';

import 'videochat.dart'; // Path to your Videochat widget

class ZoomLauncher {
  static bool _isSDKInitialized = false;
  
  static Future<Widget> initializeAndGetVideoChatWidget({
    required String appKey,
    required String appSecret,
    required Map<String, String> sessionDetails,
  }) async {
    var zoom = ZoomVideoSdk();
    
    if (!_isSDKInitialized) {
      try {
        InitConfig initConfig = InitConfig(domain: "zoom.us", enableLog: true);
        String result = await zoom.initSdk(initConfig);
        print("SDK Init result: $result");
        
        if (result == "Success" || result == "SDK is already initialized.") {
          _isSDKInitialized = true;
        } else {
          throw Exception("Zoom SDK init failed: $result");
        }
      } catch (e) {
        print("SDK initialization error: $e");
        // Try to continue - SDK might already be initialized
        _isSDKInitialized = true;
      }
    }
    
    return Videochat(
      appKey: appKey,
      appSecret: appSecret,
      sessionDetails: sessionDetails,
    );
  }
  
  static void resetSDKState() {
    _isSDKInitialized = false;
  }
}
