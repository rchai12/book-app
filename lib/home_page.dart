import 'package:bookapp/message_boards_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'authentication.dart';
import 'account_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'message_board.dart';
import 'book_search_page.dart';

class HomePage extends StatefulWidget {
  User user;
  final authService = AuthService();
  HomePage({super.key, required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _messageBoards;
  int _currentIndex = 0;
  late bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await widget.authService.logoutUser();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  final List<Widget> _pages = [];

  @override
  Widget build(BuildContext context) {
    _pages.clear();
    //_pages.add(HomeTab(user:widget.user, authService: widget.authService));
    _pages.add(BookSearchPage(user: widget.user, authService: widget.authService));
    _pages.add(MessageBoardsPage(user: widget.user, authService: widget.authService));
    _pages.add(ProfilePage(user: widget.user, authService: widget.authService));
    _pages.add(AccountPage(user: widget.user, authService: widget.authService));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Boards App'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Book Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Account Settings',
          ),
        ],
      ),
    );
  }
}
