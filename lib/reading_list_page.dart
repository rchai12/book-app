import 'package:flutter/material.dart';
import 'book.dart';
import 'book_details.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReadingListPage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const ReadingListPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<ReadingListPage> createState() => _ReadingListPageState();
}

class _ReadingListPageState extends State<ReadingListPage> {
  List<Book> _readingListBooks = [];
  Set<String> _favoriteIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => _loading = true);
    try {
      final readingList = await widget.authService.getReadingList();
      final favorites = await widget.authService.getFavorites();
      setState(() {
        _readingListBooks = readingList;
        _favoriteIds = favorites.map((book) => book.id).toSet();
      });
    } catch (e) {
      print('Error loading lists: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _toggleFavorite(Book book) async {
    if (_favoriteIds.contains(book.id)) {
      await widget.authService.removeBookFromFavorites(book.id);
      setState(() {
        _favoriteIds.remove(book.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.title} removed from Favorites!'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      await widget.authService.addBookToFavorites(book);
      setState(() {
        _favoriteIds.add(book.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.title} added to Favorites!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleRemoveFromReadingList(Book book) async {
    await widget.authService.removeBookFromReadingList(book.id);
    setState(() {
      _readingListBooks.removeWhere((b) => b.id == book.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${book.title} removed from Reading List')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Reading List')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _readingListBooks.isEmpty
              ? Center(child: Text('Your reading list is empty.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    itemCount: _readingListBooks.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder: (context, index) {
                      final book = _readingListBooks[index];
                      final isFavorite = _favoriteIds.contains(book.id);
                      return Card(
                        elevation: 5,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookDetailsPage(
                                  book: book,
                                  user: widget.user,
                                  authService: widget.authService,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (book.thumbnail.isNotEmpty)
                                Image.network(
                                  book.thumbnail,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  book.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  book.authors.join(', '),
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Spacer(),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.red : null,
                                      ),
                                      onPressed: () => _toggleFavorite(book),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.bookmark),
                                      onPressed: () =>
                                          _handleRemoveFromReadingList(book),
                                      tooltip: 'Remove from Reading List',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
