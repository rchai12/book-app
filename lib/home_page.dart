import 'package:bookapp/message_boards_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authentication.dart';
import 'account_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'book_page.dart';

class HomePage extends StatefulWidget {
  User user;
  final authService = AuthService();
  HomePage({super.key, required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedPageIndex = 0;

  final List<String> _pageTitles = [
    'Books',
    'Message Boards',
    'Profile',
    'Account Settings',
  ];

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      BookPage(user: widget.user, authService: widget.authService),
      MessageBoardsPage(user: widget.user, authService: widget.authService),
      ProfilePage(user: widget.user, authService: widget.authService),
      AccountPage(user: widget.user, authService: widget.authService),
    ];
  }

  void _logout() async {
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

  void _navigateToPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedPageIndex]),
        backgroundColor: Colors.lightGreen,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.grey[200],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.grey[400]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.menu_book, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Welcome!',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    Text(
                      widget.user.email ?? '',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.search),
                title: Text('Books'),
                onTap: () => _navigateToPage(0),
              ),
              ListTile(
                leading: Icon(Icons.forum),
                title: Text('Message Boards'),
                onTap: () => _navigateToPage(1),
              ),
              ListTile(
                leading: Icon(Icons.account_circle),
                title: Text('Profile'),
                onTap: () => _navigateToPage(2),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Account Settings'),
                onTap: () => _navigateToPage(3),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: _pages[_selectedPageIndex],
    );
  }
}
