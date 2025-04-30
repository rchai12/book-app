import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'login_page.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  WebViewPlatform.instance;
  InAppWebViewPlatform.instance;
  runApp(BookApp());
}

class BookApp extends StatelessWidget {
  const BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
        ).copyWith(
          secondary: Colors.greenAccent, // optional
        ),
        useMaterial3: true, // optional: enables Material 3 design
      ),
      home: LoginPage(),
    );
  }
}
