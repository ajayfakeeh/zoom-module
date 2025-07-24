import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:zoom_module/zoom_integration/video_full_screen.dart';
import 'package:zoom_module/zoom_integration/widgets/circle_icon_button.dart';
import 'package:zoom_module/zoom_integration/widgets/footer_button_widget.dart';
import 'package:zoom_module/zoom_integration/widgets/user_name_bottom.dart';
import 'package:zoom_module/zoom_integration/widgets/video_widget.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';

class MobileViewMultiple extends StatefulWidget {
  final List<ZoomVideoSdkUser> users;
  final String localUserId;
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final VoidCallback onLeaveSession;
  final Function(bool, bool, bool) onStateUpdate;
  final ZoomVideoSdk zoom; // Add this
  const MobileViewMultiple({
    super.key,
    required this.users,
    required this.localUserId,
    required this.isMuted,
    required this.isVideoOn,
    required this.isScreenSharing,
    required this.onLeaveSession,
    required this.onStateUpdate,
    required this.zoom, // Add this
  });

  @override
  State<MobileViewMultiple> createState() => _MobileViewMultipleState();
}

class _MobileViewMultipleState extends State<MobileViewMultiple> {
  ZoomVideoSdkUser? selectedUser;
  @override
  void initState() {
    selectedUser = widget.users[1];
    super.initState();
  }

  Future switchCamera() async {
    try {
      // Pass null to switch to next available camera (front/back)
      bool success = await widget.zoom.videoHelper.switchCamera(null);
      debugPrint('Camera switch success: $success');
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (selectedUser != null)
                  VideoWidget(
                    user: selectedUser!,
                    isMainView: true,
                    isLocalUser: selectedUser!.userId == widget.localUserId,
                    onCameraFlip: switchCamera,
                  ),
                UserNameBottom(
                  userName: selectedUser?.userName ?? "",
                  position: 4,
                ),
                if (selectedUser != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleIconButton(
                      icon: Icons.fullscreen,
                      iconColor: Colors.black,
                      backgroundColor: Colors.white,
                      tooltip: "Fullscreen",
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    VideoFullScreen(user: selectedUser!)));
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            width: MediaQuery.of(context).size.width,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = 120 * (9 / 16) +
                    6; // item width + margin * 2 (3 on left + 3 on right)
                final totalWidth = itemWidth * widget.users.length;
                final availableWidth = constraints.maxWidth;

                if (totalWidth < availableWidth) {
                  /// Center content when list is not scrollable
                  return Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: totalWidth,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.users.length,
                        itemBuilder: (context, index) {
                          return itemCardUI(index);
                        },
                      ),
                    ),
                  );
                } else {
                  /// Normal scrollable list
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.users.length,
                    itemBuilder: (context, index) {
                      return itemCardUI(index);
                    },
                  );
                }
              },
            ),
          ),
          FooterButtonWidget(
            isMuted: widget.isMuted,
            isVideoOn: widget.isVideoOn,
            isScreenSharing: widget.isScreenSharing,
            onLeaveSession: widget.onLeaveSession,
            zoom: widget.zoom,
            onStateUpdate: widget.onStateUpdate,
            users: widget.users,
          ),
        ],
      ),
    );
  }

  Widget itemCardUI(int index) {
    return Container(
      margin: const EdgeInsets.all(3),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      decoration: BoxDecoration(
        border: Border.all(
          color:
              selectedUser == widget.users[index] ? Colors.blue : Colors.black,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: VideoWidget(
              user: widget.users[index],
              isMainView: false,
              borderRadius: 4,
              onTap: () {
                setState(() {
                  selectedUser = widget.users[index];
                });
              },
              isLocalUser: widget.users[index].userId == widget.localUserId,
              onCameraFlip: switchCamera,
            ),
          ),
          UserNameBottom(userName: widget.users[index].userName, position: 4),
        ],
      ),
    );
  }
}
