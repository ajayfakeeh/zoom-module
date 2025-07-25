import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:zoom_module/zoom_integration/widgets/video_widget.dart';

class FloatingUserWidget extends StatelessWidget {
  final List<ZoomVideoSdkUser> otherUsers;
  final Function(ZoomVideoSdkUser) onTap;
  final VoidCallback switchCamera;
  final String localUserId;
  const FloatingUserWidget({
    super.key,
    required this.otherUsers,
    required this.onTap,
    required this.switchCamera,
    required this.localUserId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;

        final tileWidth = isTablet ? 220.0 : 110.0;
        final aspectRatio = 9 / 16;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: otherUsers.map((user) {
            return Container(
              width: tileWidth,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: VideoWidget(
                  user: user,
                  isMainView: false,
                  onTap: () => onTap(user),
                  onCameraFlip: switchCamera,
                  borderRadius: 16,
                  isLocalUser: user.userId == localUserId,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
