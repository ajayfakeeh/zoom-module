import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zoom_module/zoomintegration/ZoomLauncher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, dynamic>? _zoomArgs;
  static const MethodChannel _channel = MethodChannel('flutter_zoom_videosdk');

  @override
  void initState() {
    super.initState();

    _channel.setMethodCallHandler(_handleNativeMethodCall);
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'joinSession') {
      final args = Map<String, dynamic>.from(call.arguments);
      debugPrint("✅ Received from native: $args");

      // Trigger widget rebuild with new args
      setState(() {
        _zoomArgs = args;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoom SDK Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(zoomArgs: _zoomArgs),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic>? zoomArgs;

  const HomeScreen({super.key, required this.zoomArgs});

  @override
  Widget build(BuildContext context) {
    if (zoomArgs == null) {
      return const Scaffold(
        body: Center(child: Text("Waiting for Zoom parameters...")),
      );
    }

    return Scaffold(
      body: FutureBuilder<Widget>(
        future: ZoomLauncher.initializeAndGetVideoChatWidget(
          appKey: zoomArgs!['appKey'],
          appSecret: zoomArgs!['appSecret'],
          sessionDetails: {
            "sessionName": zoomArgs!['sessionName'],
            "sessionPassword": zoomArgs!['sessionPassword'],
            "displayName": zoomArgs!['displayName'],
            "roleType": zoomArgs!['roleType'],
            "sessionTimeout": zoomArgs!['sessionTimeout'],
          },
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}
