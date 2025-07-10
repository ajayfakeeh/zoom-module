import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_event_listener.dart';
import 'package:html_unescape/html_unescape.dart';
import 'ChatSheet.dart';

class ChatManager {
  static final ChatManager _instance = ChatManager._internal();
  factory ChatManager() => _instance;
  ChatManager._internal();

  static final List<ChatMessage> _messages = [];
  StreamSubscription? _chatSubscription;
  String? _myUserId;
  VoidCallback? _onMessageReceived;

  List<ChatMessage> get messages => _messages;

  void initialize(String myUserId) {
    _myUserId = myUserId;
    _chatSubscription?.cancel();
    _chatSubscription = ZoomVideoSdkEventListener().addListener(
      EventType.onChatNewMessageNotify,
      _handleNewMessage,
    );
  }

  void setMessageCallback(VoidCallback? callback) {
    _onMessageReceived = callback;
  }

  void _handleNewMessage(dynamic data) {
    try {
      final messageData = data is String ? jsonDecode(data) : data;
      final messageMap = messageData['message'] is String 
          ? jsonDecode(messageData['message']) 
          : messageData['message'];
      
      String senderId = '';
      if (messageMap['senderUser'] != null) {
        try {
          final unescape = HtmlUnescape();
          final senderUserString = messageMap["senderUser"];
          final decodedString = unescape.convert(senderUserString);
          final senderUserMap = jsonDecode(decodedString);
          senderId = senderUserMap['userId'] ?? '';
        } catch (e) {
          debugPrint("Error parsing sender: $e");
        }
      }
      
      final content = messageMap['content'] ?? 'No message';
      final isMe = senderId == _myUserId;
      
      try {
        final jsonContent = jsonDecode(content);
        _messages.add(ChatMessage(
          content: jsonContent['content'] ?? content,
          isMe: isMe,
          contentType: jsonContent['content_type'] ?? 'Text',
          filePath: jsonContent['file_path'] ?? '',
        ));
      } catch (e) {
        _messages.add(ChatMessage(content: content, isMe: isMe));
      }
      
      _onMessageReceived?.call();
    } catch (e) {
      debugPrint("Error handling message: $e");
    }
  }

  void dispose() {
    _chatSubscription?.cancel();
    _chatSubscription = null;
    _messages.clear();
  }
}