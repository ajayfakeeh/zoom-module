import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zoom_module/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🧱 Enable immersive sticky UI mode: full screen with transient system bars.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 🎨 Customize system UI overlays for dark mode (dark background, light icons).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar.
      systemNavigationBarColor: Colors.black, // Black navigation bar.
      statusBarIconBrightness: Brightness.light, // Light icons on status bar.
      systemNavigationBarIconBrightness:
          Brightness.light, // Light nav bar icons.
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const MyApp());
}

/// The root widget of the app.
/// Handles receiving method calls from native code to start Zoom sessions.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, dynamic>? _zoomArgs;

  // MethodChannel for communicating with native platform code.
  static const MethodChannel _channel = MethodChannel('flutter_zoom_videosdk');

  @override
  void initState() {
    super.initState();

    // Register the native method call handler.
    _channel.setMethodCallHandler(_handleNativeMethodCall);
    debugPrint("[MyApp] Initialized MethodChannel handler.");
  }

  /// Handles calls from native platform via MethodChannel.
  ///
  /// Expects 'joinSession' method with arguments containing Zoom session details.
  Future<void> _handleNativeMethodCall(MethodCall call) async {
    debugPrint("[MyApp] Received native method call: ${call.method}");

    if (call.method == 'joinSession') {
      try {
        final args = Map<String, dynamic>.from(call.arguments);
        debugPrint("[MyApp] joinSession args: $args");

        // Update state with new Zoom session arguments to rebuild UI.
        setState(() {
          _zoomArgs = args;
        });
      } catch (e, stacktrace) {
        debugPrint("[MyApp] Error processing joinSession args: $e");
        debugPrint(stacktrace.toString());
      }
    } else {
      debugPrint("[MyApp] Unhandled native method: ${call.method}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.blueAccent,
          secondary: Colors.lightBlueAccent,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.grey,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      builder: (context, child) {
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        );
      },
      home: HomeScreen(zoomArgs: _zoomArgs),
    );
  }
}
