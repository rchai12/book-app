import 'package:flutter/material.dart';
import 'book.dart';
import 'authentication.dart';
import 'book_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reading_status.dart';

class ReadingStatusPage extends StatefulWidget {
  final ReadingStatus status;
  User user;
  final AuthService authService;

  ReadingStatusPage({
    super.key,
    required this.status,
    required this.user,
    required this.authService,
  });

  @override
  State<ReadingStatusPage> createState() => _ReadingStatusPageState();
}

class _ReadingStatusPageState extends State<ReadingStatusPage> {
  List<Book> _books = [];
  Set<String> _favoriteIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _loading = true);
    try {
      final readingList = await widget.authService.getReadingList();
      final favorites = await widget.authService.getFavorites();
      setState(() {
        _books = readingList.where((book) => book.readingStatus == widget.status).toList();
        _favoriteIds = favorites.map((b) => b.id).toSet();
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _toggleFavorite(Book book) async {
    if (_favoriteIds.contains(book.id)) {
      await widget.authService.removeBookFromFavorites(book.id);
      setState(() => _favoriteIds.remove(book.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.title} removed from Favorites!'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      await widget.authService.addBookToFavorites(book);
      setState(() => _favoriteIds.add(book.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.title} added to Favorites!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeBook(Book book) async {
    await widget.authService.removeBookFromReadingList(book.id);
    setState(() => _books.removeWhere((b) => b.id == book.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${book.title} removed from reading list!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  ReadingStatus getNextStatus(ReadingStatus current) {
    switch (current) {
      case ReadingStatus.wantToRead:
        return ReadingStatus.currentlyReading;
      case ReadingStatus.currentlyReading:
        return ReadingStatus.finished;
      case ReadingStatus.finished:
        return ReadingStatus.wantToRead;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());

    if (_books.isEmpty) return Center(child: Text('No books in this list.'));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: _books.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.6,
        ),
        itemBuilder: (context, index) {
          final book = _books[index];
          final isFavorite = _favoriteIds.contains(book.id);
          return Card(
            elevation: 5,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailsPage(
                    book: book,
                    user: widget.user,
                    authService: widget.authService,
                  ),
                ),
              ),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          icon: Icon(Icons.bookmark_remove),
                          onPressed: () => _removeBook(book),
                          tooltip: 'Remove from Reading List',
                        ),
                        IconButton(
                          icon: Icon(Icons.sync_alt),
                          tooltip: 'Move to Next Status',
                          onPressed: () async {
                            if (book.readingStatus != null) {
                              final nextStatus = getNextStatus(book.readingStatus!);
                              await widget.authService.changeReadingStatus(book.id, nextStatus);
                              setState(() {
                                _books.removeWhere((b) => b.id == book.id);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${book.title} moved to ${nextStatus.label}.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
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
    );
  }
}
