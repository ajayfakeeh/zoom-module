# Zoom Module for Flutter

A Flutter module that provides Zoom Video SDK integration with simple APIs for joining meetings, managing audio/video, chat, and more.

## Features

- Initialize and join Zoom sessions
- Toggle video on/off
- Mute/unmute audio
- Send chat messages (to all or specific participants)
- End call functionality
- View participants list
- Simple UI components for Zoom meetings

## Getting Started

### Prerequisites

1. Sign up for a [Zoom Developer Account](https://developers.zoom.us/)
2. Create a Video SDK app and get your SDK Key and Secret
3. Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_zoom_videosdk: ^2.1.10
  dart_jsonwebtoken: ^2.17.0
  permission_handler: ^11.3.0
```

### Setup

1. Update the `config.dart` file with your Zoom SDK Key and Secret:

```dart
const Map config = {
  'ZOOM_SDK_KEY': 'YOUR_ZOOM_SDK_KEY',
  'ZOOM_SDK_SECRET': 'YOUR_ZOOM_SDK_SECRET',
};
```

2. Configure session details in `config.dart`:

```dart
const Map sessionDetails = {
  'sessionName': 'Your Session Name',
  'sessionPassword': 'password', // Optional
  'displayName': 'Your Name',
  'sessionTimeout': '40', // In minutes
  'roleType': '1', // 1 for host, 0 for attendee
};
```

## Usage

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:zoom_module/zoom_module.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ZoomModule _zoomModule = ZoomModule();
  Widget? _zoomView;
  
  @override
  void initState() {
    super.initState();
    _initializeZoom();
  }
  
  Future<void> _initializeZoom() async {
    await _zoomModule.initialize();
  }
  
  Future<void> _joinMeeting() async {
    final zoomView = await _zoomModule.joinSession(
      sessionName: 'My Meeting',
      displayName: 'John Doe',
      onSessionEnded: () {
        setState(() {
          _zoomView = null;
        });
      },
    );
    
    setState(() {
      _zoomView = zoomView;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_zoomView != null) {
      return _zoomView!;
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Zoom Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: _joinMeeting,
          child: Text('Join Meeting'),
        ),
      ),
    );
  }
}
```

### Advanced Usage

```dart
// Toggle video
bool isVideoOn = await _zoomModule.toggleVideo();

// Toggle audio
bool isAudioOn = await _zoomModule.toggleAudio();

// Send chat message to everyone
await _zoomModule.sendChatMessage('Hello everyone!');

// Get participants
List participants = await _zoomModule.getParticipants();

// Leave session
await _zoomModule.leaveSession();
```

## Important Note

This module generates JWTs on the device for demonstration purposes. In a production environment, you should generate JWTs on a secure server and provide them to your app to ensure your SDK secret remains secure.

## License

This project is licensed under the MIT License - see the LICENSE file for details.