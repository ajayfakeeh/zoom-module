import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_event_listener.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:zoom_module/zoom_integration/chat_sheet.dart';

class ChatManager {
  static final ChatManager _instance = ChatManager._internal();
  factory ChatManager() => _instance;
  ChatManager._internal();

  final List<ChatMessage> _messages = [];
  StreamSubscription? _chatSubscription;
  String? _myUserId;
  VoidCallback? _onMessageReceived;
  int _unreadCount = 0;

  List<ChatMessage> get messages => _messages;
  int get unreadCount => _unreadCount;

  bool get isInitialized => _chatSubscription != null;

  /// Initialize the ChatManager and listen to incoming messages
  void initialize(String myUserId, ZoomVideoSdkEventListener listener) {
    _myUserId = myUserId;
    _chatSubscription?.cancel();

    try {
      _chatSubscription = listener.addListener(
        EventType.onChatNewMessageNotify,
        _handleNewMessage,
      );
      debugPrint('✅ ChatManager initialized with userId: $_myUserId');
    } catch (e) {
      debugPrint('❌ Failed to initialize ChatManager: $e');
    }
  }

  /// Set the UI callback (e.g., footer badge update)
  void setMessageCallback(VoidCallback? callback) {
    _onMessageReceived = callback;
    debugPrint('📩 ChatManager callback set: $callback');
  }

  /// Handle incoming chat messages
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
          debugPrint("⚠️ Error parsing senderUser: $e");
        }
      }

      final isMe = senderId == _myUserId;
      final content = messageMap['content'] ?? 'No message';

      try {
        final jsonContent = jsonDecode(content);
        _messages.add(ChatMessage(
          content: jsonContent['content'] ?? content,
          isMe: isMe,
          contentType: jsonContent['content_type'] ?? 'Text',
          filePath: jsonContent['file_path'] ?? '',
        ));
      } catch (e) {
        debugPrint("⚠️ Could not parse JSON content, storing raw.");
        _messages.add(ChatMessage(content: content, isMe: isMe));
      }

      if (!isMe) {
        _unreadCount++;
        debugPrint('🔔 New message received from other user. Unread count: $_unreadCount');
      } else {
        debugPrint('📨 Message sent by self, not counted as unread.');
      }

      _onMessageReceived?.call();
    } catch (e) {
      debugPrint("❌ Error handling incoming chat message: $e");
    }
  }

  /// Call this when chat is opened to clear the badge
  void clearUnreadCount() {
    _unreadCount = 0;
    debugPrint('🔄 Unread count cleared.');
    // _onMessageReceived?.call();
  }

  /// Call only when session ends
  void dispose() {
    try {
      _chatSubscription?.cancel();
      _chatSubscription = null;
      _messages.clear();
      _unreadCount = 0;
      _onMessageReceived = null;
      _myUserId = null;

      debugPrint('🧹 ChatManager disposed after session end.');
    } catch (e) {
      debugPrint('❌ Error during ChatManager disposal: $e');
    }
  }
}
