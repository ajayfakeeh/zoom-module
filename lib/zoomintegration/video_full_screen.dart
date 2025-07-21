import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:zoom_module/zoomintegration/widgets/circle_icon_button.dart';
import 'package:zoom_module/zoomintegration/widgets/video_widget.dart';

class VideoFullScreen extends StatefulWidget {
  final ZoomVideoSdkUser user;
  const VideoFullScreen({super.key, required this.user});

  @override
  State<VideoFullScreen> createState() => _VideoFullScreenState();
}

class _VideoFullScreenState extends State<VideoFullScreen> {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            VideoWidget(
              user: widget.user,
              isMainView: true,
            ),
            Positioned(
              top: 16,
              right: 16,
              child: CircleIconButton(
                icon: Icons.fullscreen_exit,
                iconColor: Colors.black,
                backgroundColor: Colors.white,
                tooltip: "Exit Fullscreen",
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
