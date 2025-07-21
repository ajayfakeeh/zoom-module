import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:zoom_module/zoomintegration/widgets/video_widget.dart';

class FloatingUserWidget extends StatelessWidget {
  final List<ZoomVideoSdkUser> otherUsers;
  final Function(ZoomVideoSdkUser) onTap;
  const FloatingUserWidget({
    super.key,
    required this.otherUsers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;

        final tileWidth = isTablet ? 250.0 : 110.0;
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
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
