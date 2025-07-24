import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/flutter_zoom_view.dart' as zoom_view;
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';

class VideoWidget extends StatelessWidget {
  final ZoomVideoSdkUser user;
  final bool isMainView;
  final double? borderRadius;
  final bool isLocalUser;
  final VoidCallback? onTap;
  final VoidCallback? onCameraFlip;

  const VideoWidget({
    super.key,
    required this.user,
    this.isMainView = false,
    this.borderRadius,
    this.isLocalUser = false,
    this.onTap,
    this.onCameraFlip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius:
      isMainView ? null : BorderRadius.circular(borderRadius ?? 8),
      child: ClipRRect(
        borderRadius: isMainView
            ? BorderRadius.zero
            : BorderRadius.circular(borderRadius ?? 8),
        child: SizedBox.expand(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: FutureBuilder<bool>(
              key: Key('${user.userId}_video_status'),
              future: user.videoStatus?.isOn(),
              builder: (context, snapshot) {
                final isVideoOn = snapshot.data ?? false;

                if (!isVideoOn) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onTap,
                    child: Container(
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
                              user.userName,
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
                    ),
                  );
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    zoom_view.View(
                      key: Key('${user.userId}_video'),
                      creationParams: {
                        "userId": user.userId,
                        "videoAspect": VideoAspect.FullFilled,
                        "fullScreen": false,
                      },
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: onTap,
                      ),
                    ),
                    if (isVideoOn && isLocalUser && onCameraFlip != null)
                      Positioned(
                        top: 8,
                        child: Center(
                          child: GestureDetector(
                            onTap: onCameraFlip,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.flip_camera_ios,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
