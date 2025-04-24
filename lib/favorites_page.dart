import 'package:bookapp/reading_status.dart';
import 'package:flutter/material.dart';
import 'book.dart';
import 'book_details.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesPage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const FavoritesPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Book> _favoriteBooks = [];
  Set<String> _readingListIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => _loading = true);
    try {
      final favorites = await widget.authService.getFavorites();
      final readingList = await widget.authService.getReadingList();

      setState(() {
        _favoriteBooks = favorites;
        _readingListIds = readingList.map((book) => book.id).toSet();
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeFromFavorites(String bookId) async {
    await widget.authService.removeBookFromFavorites(bookId);
    setState(() {
      _favoriteBooks.removeWhere((book) => book.id == bookId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed from favorites'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handleAddToReadingList(Book book) async {
    final isInReadingList = _readingListIds.contains(book.id);
    try {
      if (isInReadingList) {
        await widget.authService.removeBookFromReadingList(book.id);
        _readingListIds.remove(book.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from Reading List'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        await widget.authService.addBookToReadingList(book: book, status: ReadingStatus.wantToRead);
        _readingListIds.add(book.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to Reading List'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      setState(() {});
    } catch (e) {
      print('Error updating reading list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Favorites')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _favoriteBooks.isEmpty
              ? Center(child: Text('No favorite books yet.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    itemCount: _favoriteBooks.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder: (context, index) {
                      final book = _favoriteBooks[index];
                      final isInReadingList = _readingListIds.contains(book.id);
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
                                        Icons.favorite,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _removeFromFavorites(book.id),
                                      tooltip: 'Remove from Favorites',
                                      iconSize: 20,
                                      constraints: BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _readingListIds.contains(book.id)
                                            ? Icons.bookmark
                                            : Icons.bookmark_outline,
                                      ),
                                      tooltip: _readingListIds.contains(book.id)
                                          ? 'Already in Reading List'
                                          : 'Read Later',
                                      onPressed: () => _handleAddToReadingList(book),
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
