import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_event_listener.dart';
import 'package:html_unescape/html_unescape.dart';

class ChatSheet extends StatefulWidget {
  const ChatSheet({super.key});

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<String> messages = [];
  final ZoomVideoSdk zoom = ZoomVideoSdk();
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _chatSubscription = ZoomVideoSdkEventListener().addListener(
      EventType.onChatNewMessageNotify,
      _handleNewMessage,
    );
  }

  void _handleNewMessage(dynamic data) {
    try {
      debugPrint("Chat message received: $data");
      
      // Parse the message data
      final messageData = data is String ? jsonDecode(data) : data;
      final messageMap = messageData['message'] is String 
          ? jsonDecode(messageData['message']) 
          : messageData['message'];
      
      // Get the sender user info
      String senderName = 'Unknown';
      if (messageMap['senderUser'] != null) {
        try {
          final unescape = HtmlUnescape();
          final senderUserString = messageMap["senderUser"];
          final decodedString = unescape.convert(senderUserString);
          final senderUserMap = jsonDecode(decodedString);
          senderName = senderUserMap['userName'] ?? 'Unknown';
        } catch (e) {
          debugPrint("Error parsing sender: $e");
        }
      }
      
      // Get the message content
      final content = messageMap['content'] ?? 'No message';
      
      // Add the message to the list
      setState(() => messages.add("$senderName: $content"));
    } catch (e) {
      debugPrint("Error handling message: $e");
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await zoom.chatHelper.sendChatToAll(text);
    setState(() => messages.add("Me: $text"));
    _controller.clear();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 400,
        child: Column(
          children: [
            const Text(
              "Chat",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    messages[index],
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                      filled: true,
                      fillColor: Colors.blue,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
