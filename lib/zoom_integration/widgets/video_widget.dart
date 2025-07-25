import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/flutter_zoom_view.dart' as zoom_view;
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'user_avatar.dart';

class VideoWidget extends StatelessWidget {
  final ZoomVideoSdkUser user;
  final bool isMainView;
  final double? borderRadius;
  final bool isLocalUser;
  final VoidCallback? onTap;
  final VoidCallback? onCameraFlip;
  final bool? isTabView;

  const VideoWidget({
    super.key,
    required this.user,
    this.isMainView = false,
    this.borderRadius,
    this.isLocalUser = false,
    this.onTap,
    this.onCameraFlip,
    this.isTabView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: isMainView ? null : BorderRadius.circular(borderRadius ?? 8),
        border: !isMainView ? Border.all(color: Colors.white, width: 2) : null,
      ),
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
                    child: Stack(
                      children: [
                        UserAvatar(
                          userName: user.userName,
                          isMainView:isMainView,
                          isTabView:isTabView,
                        ),
                        // Mute icon for avatar view - only for non-main views
                        if (!isMainView)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: FutureBuilder<bool>(
                              future: user.audioStatus?.isMuted(),
                              builder: (context, snapshot) {
                                final isMuted = snapshot.data ?? true;
                                if (!isMuted) return const SizedBox.shrink();
                                
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.mic_off,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
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
                    // Mute icon overlay - only for non-main views
                    if (!isMainView)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: FutureBuilder<bool>(
                          future: user.audioStatus?.isMuted(),
                          builder: (context, snapshot) {
                            final isMuted = snapshot.data ?? true;
                            if (!isMuted) return const SizedBox.shrink();
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.mic_off,
                                color: Colors.white,
                                size: 16,
                              ),
                            );
                          },
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
