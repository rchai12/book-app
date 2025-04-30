import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authentication.dart';
import 'book_search_page.dart';
import 'trending_page.dart';
import 'favorites_page.dart';
import 'reading_list_page.dart';
import 'recommended_page.dart';

class BookPage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const BookPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      BookSearchPage(user: widget.user, authService: widget.authService),
      TrendingBooksPage(user: widget.user, authService: widget.authService),
      RecommendedPage(user: widget.user, authService: widget.authService),
      FavoritesPage(user: widget.user, authService: widget.authService),
      ReadingListPage(user: widget.user, authService: widget.authService),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.trending_up),
      label: 'Trending',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.recommend),
      label: 'Recommended',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.favorite),
      label: 'Favorites',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bookmark),
      label: 'Reading List',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
        selectedItemColor: const Color.fromARGB(255, 16, 194, 22),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
