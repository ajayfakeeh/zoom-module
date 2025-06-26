import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_event_listener.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ChatSheet extends StatefulWidget {
  const ChatSheet({super.key});

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class ChatMessage {
  final String content;
  final bool isMe;
  final String contentType;
  final String filePath;
  final String? localImagePath;
  final bool isUploading;
  final double uploadProgress;
  
  ChatMessage({
    required this.content, 
    required this.isMe, 
    this.contentType = 'Text', 
    this.filePath = '',
    this.localImagePath,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });
}

class _ChatSheetState extends State<ChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> messages = [];
  final ZoomVideoSdk zoom = ZoomVideoSdk();
  StreamSubscription? _chatSubscription;
  String? myUserId;

  @override
  void initState() {
    super.initState();
    _initMyUserId();
    _chatSubscription = ZoomVideoSdkEventListener().addListener(
      EventType.onChatNewMessageNotify,
      _handleNewMessage,
    );
  }

  void _initMyUserId() async {
    final mySelf = await zoom.session.getMySelf();
    myUserId = mySelf?.userId;
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
      final isMe = senderId == myUserId;
      
      // Try to parse JSON message
      try {
        final jsonContent = jsonDecode(content);
        setState(() => messages.add(ChatMessage(
          content: jsonContent['content'] ?? content,
          isMe: isMe,
          contentType: jsonContent['content_type'] ?? 'Text',
          filePath: jsonContent['file_path'] ?? '',
        )));
      } catch (e) {
        // If not JSON, treat as plain text
        setState(() => messages.add(ChatMessage(content: content, isMe: isMe)));
      }
    } catch (e) {
      debugPrint("Error handling message: $e");
    }
  }

  /*void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await zoom.chatHelper.sendChatToAll(text);
    setState(() => messages.add("Me: $text"));
    _controller.clear();
  }*/

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    final jsonMessage = jsonEncode({
      "content_type": "Text",
      "content": text,
      "file_path": ""
    });
    
    await zoom.chatHelper.sendChatToAll(jsonMessage);
    _controller.clear();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;
    
    // Add uploading message immediately
    final uploadingMessage = ChatMessage(
      content: "Uploading image...",
      isMe: true,
      contentType: "Image",
      localImagePath: image.path,
      isUploading: true,
    );
    
    setState(() => messages.add(uploadingMessage));
    final messageIndex = messages.length - 1;
    
    try {
      final imageUrl = await _uploadImageWithProgress(File(image.path), (progress) {
        setState(() {
          messages[messageIndex] = ChatMessage(
            content: "Uploading... ${(progress * 100).toInt()}%",
            isMe: true,
            contentType: "Image",
            localImagePath: image.path,
            isUploading: true,
            uploadProgress: progress,
          );
        });
      });
      
      // Remove uploading message and send actual message
      setState(() => messages.removeAt(messageIndex));
      
      final jsonMessage = jsonEncode({
        "content_type": "Image",
        "content": "Image shared",
        "file_path": imageUrl
      });
      
      await zoom.chatHelper.sendChatToAll(jsonMessage);
    } catch (e) {
      // Update message to show error
      setState(() {
        messages[messageIndex] = ChatMessage(
          content: "Upload failed",
          isMe: true,
          contentType: "Text",
        );
      });
      debugPrint("Error uploading image: $e");
    }
  }

  Future<String> _uploadImageWithProgress(File imageFile, Function(double) onProgress) async {
    const uploadUrl = "https://your-server.com/upload"; // Replace with your server URL
    
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    
    var streamedResponse = await request.send();
    
    // Simulate progress updates (replace with actual progress tracking if your server supports it)
    for (double i = 0.1; i <= 1.0; i += 0.1) {
      await Future.delayed(const Duration(milliseconds: 200));
      onProgress(i);
    }
    
    var responseData = await streamedResponse.stream.bytesToString();
    var jsonResponse = jsonDecode(responseData);
    
    return jsonResponse['url'] ?? ''; // Adjust based on your server response
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
                itemBuilder: (_, index) {
                  final message = messages[index];
                  return Align(
                    alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.isMe ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: message.contentType == 'Image'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    // Show local image if uploading, network image if uploaded
                                    message.isUploading && message.localImagePath != null
                                        ? Image.file(File(message.localImagePath!), height: 150, fit: BoxFit.cover)
                                        : message.filePath.isNotEmpty
                                            ? Image.network(message.filePath, height: 150, fit: BoxFit.cover)
                                            : Container(height: 150, color: Colors.grey),
                                    // Progress indicator overlay
                                    if (message.isUploading)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black54,
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircularProgressIndicator(
                                                  value: message.uploadProgress,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${(message.uploadProgress * 100).toInt()}%',
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (message.content.isNotEmpty) 
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      message.content, 
                                      style: TextStyle(color: message.isMe ? Colors.white : Colors.black)
                                    ),
                                  ),
                              ],
                            )
                          : Text(
                              message.content,
                              style: TextStyle(color: message.isMe ? Colors.white : Colors.black),
                            ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.blue),
                  onPressed: _pickAndUploadImage,
                ),
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
