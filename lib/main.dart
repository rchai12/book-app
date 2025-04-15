import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'book_search_page.dart';
import 'login_page.dart';
import 'trending_page.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await WebViewPlatform.instance;
  await InAppWebViewPlatform.instance;
  runApp(BookApp());
}

class BookApp extends StatelessWidget {
  BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TrendingBooksPage(),
    );
  }
}
