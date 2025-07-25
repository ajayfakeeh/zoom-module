import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_session.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';

class ZoomInfoBottomSheet extends StatefulWidget {
  final ZoomVideoSdk zoom;

  const ZoomInfoBottomSheet({super.key, required this.zoom});

  @override
  State<ZoomInfoBottomSheet> createState() => _ZoomInfoBottomSheetState();
}

class _ZoomInfoBottomSheetState extends State<ZoomInfoBottomSheet> {
  ZoomVideoSdkSession? session;
  ZoomVideoSdkUser? mySelf;

  String sessionId = "";
  String sessionPassword = "";
  String sessionTopic = "";
  String userName = "";
  String userId = "";

  @override
  void initState() {
    getSessionUser();
    super.initState();
  }

  void getSessionUser() async {
    session = widget.zoom.session;
    mySelf = await session?.getMySelf();
    debugPrint("Session $session");
    debugPrint("MySelf $mySelf");
    var tempSessionId = await session?.getSessionID();
    var tempSessionPassword = await session?.getSessionPassword();
    var tempSessionTopic = await session?.getSessionPassword();
    setState(() {
      sessionId = tempSessionId ?? "N/A";
      sessionPassword = tempSessionPassword ?? "N/A";
      sessionTopic = tempSessionTopic ?? "N/A";
      userName = mySelf?.userName ?? "N/A";
      userId = mySelf?.userId ?? "N/A";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Session Info',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _infoRow('Session ID', sessionId),
          _infoRow('Password', sessionPassword),
          _infoRow('Topic', sessionTopic),
          _infoRow('User Name', userName),
          _infoRow('User ID', userId),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$label:",
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
