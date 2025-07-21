import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zoom_module/zoomintegration/ZoomLauncher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🧱 UI Mode: Enables immersive full screen mode.
  /// Hides both the status bar and navigation bar,
  /// but they temporarily reappear when the user swipes from the edges.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  /// 🎨 Overlay Style: Customizes the appearance of system UI overlays
  /// like the status bar and navigation bar.
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      /// 🔍 Status Bar Background: Transparent so your content can extend behind it.
      statusBarColor: Colors.transparent,

      /// 📱 Navigation Bar Background: Black by default (can be transparent for full UI control).
      systemNavigationBarColor: Colors.black,

      /// 🌙 Status Bar Icons: Light icons for visibility on dark backgrounds.
      statusBarIconBrightness: Brightness.light,

      /// 🌙 Navigation Bar Icons: Also light-colored for consistency.
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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
