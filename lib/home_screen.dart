import 'package:flutter/material.dart';
import 'package:zoom_module/zoom_integration/zoom_launcher.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic>? zoomArgs;

  const HomeScreen({super.key, required this.zoomArgs});

  @override
  Widget build(BuildContext context) {
    if (zoomArgs == null) {
      return const Scaffold(
        body: Center(child: Text("Waiting for Zoom parameters...")),
      );
    }

    return Scaffold(
      body: FutureBuilder<Widget>(
        future: ZoomLauncher.initializeAndGetVideoChatWidget(
          appKey: zoomArgs!['appKey'],
          appSecret: zoomArgs!['appSecret'],
          sessionDetails: {
            "sessionName": zoomArgs!['sessionName'],
            "sessionPassword": zoomArgs!['sessionPassword'],
            "displayName": zoomArgs!['displayName'],
            "roleType": zoomArgs!['roleType'],
            "sessionTimeout": zoomArgs!['sessionTimeout'],
          },
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}