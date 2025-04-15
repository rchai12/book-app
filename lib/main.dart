import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'book_search_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(BookApp());
}

class BookApp extends StatelessWidget {
  BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BookSearchPage(),
    );
  }
}
