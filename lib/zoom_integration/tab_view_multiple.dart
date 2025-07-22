import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:zoom_module/zoom_integration/widgets/circle_icon_button.dart';
import 'package:zoom_module/zoom_integration/widgets/control_bar.dart';
import 'package:zoom_module/zoom_integration/widgets/user_name_bottom.dart';
import 'package:zoom_module/zoom_integration/widgets/video_widget.dart';

class TabViewMultiple extends StatefulWidget {
  final List<ZoomVideoSdkUser> users;
  final String? activeSpeakerId;
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final VoidCallback onLeaveSession;
  final Function(bool, bool, bool) onStateUpdate;
  final ZoomVideoSdk zoom; // Add this
  const TabViewMultiple({
    super.key,
    required this.users,
    this.activeSpeakerId,
    required this.isMuted,
    required this.isVideoOn,
    required this.isScreenSharing,
    required this.onLeaveSession,
    required this.onStateUpdate,
    required this.zoom,
  });

  @override
  State<TabViewMultiple> createState() => _TabViewMultipleState();
}

class _TabViewMultipleState extends State<TabViewMultiple> {
  ZoomVideoSdkUser? selectedUser;
  bool isListVisible = true;
  @override
  void initState() {
    selectedUser = widget.users[1];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            if (selectedUser != null)
              Positioned.fill(
                child: VideoWidget(user: selectedUser!, isMainView: true),
              ),
            UserNameBottom(
              userName: selectedUser?.userName ?? "",
              position: 16,
            ),
            ControlBar(
              isMuted: widget.isMuted,
              isVideoOn: widget.isVideoOn,
              isScreenSharing: widget.isScreenSharing,
              onLeaveSession: widget.onLeaveSession,
              zoom: widget.zoom,
              onStateUpdate: widget.onStateUpdate,
            ),
            Positioned(
              right: 40,
              top: 0,
              child: CircleIconButton(
                icon: isListVisible
                    ? Icons.chevron_right
                    : Icons.chevron_left,
                iconColor: Colors.blue,
                backgroundColor: Colors.white,
                tooltip: "Hide/Show",
                onPressed: () {
                  setState(() {
                    isListVisible = !isListVisible;
                  });
                },
              ),
            ),
            Positioned(
              right: 0,
              top: 100,
              bottom: 0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: isListVisible ? 200.0 : 0,
                color: Colors.transparent,
                child: isListVisible
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return ListView.builder(
                            physics: BouncingScrollPhysics(),
                            itemCount: widget.users.length,
                            itemBuilder: (context, index) {
                              return itemCardUI(index);
                            },
                          );
                        },
                      )
                    : SizedBox.shrink(),
              ),
            ),
          ],
        ),
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
            ),
          ),
          UserNameBottom(userName: widget.users[index].userName, position: 4),
        ],
      ),
    );
  }
}
