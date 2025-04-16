import 'package:flutter/material.dart';
import 'book.dart';
import 'preview_page.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reading_status.dart';

class BookDetailsPage extends StatefulWidget {
  final Book book;
  final User user;
  final AuthService authService;

  const BookDetailsPage({
    Key? key,
    required this.book,
    required this.user,
    required this.authService,
  }) : super(key: key);

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  bool _isFavorited = false;
  bool _inReadingList = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _checkReadingListStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await widget.authService.isBookInFavorites(widget.book.id);
    setState(() {
      _isFavorited = isFavorite;
    });
  }

  Future<void> _checkReadingListStatus() async {
    final isInList = await widget.authService.isBookInReadingList(widget.book.id);
    setState(() {
      _inReadingList = isInList;
    });
  }

  void _toggleFavorite() async {
    if (_isFavorited) {
      await widget.authService.removeBookFromFavorites(widget.book.id);
    } else {
      await widget.authService.addBookToFavorites(widget.book);
    }
    setState(() {
      _isFavorited = !_isFavorited;
    });
  }

  void _toggleReadingList() async {
    if (_inReadingList) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This book is already in your reading list.'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      await widget.authService.addBookToReadingList(
        book: widget.book,
        status: ReadingStatus.wantToRead,
      );
      setState(() {
        _inReadingList = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book added to your reading list.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book.thumbnail.isNotEmpty)
              Center(
                child: Image.network(
                  book.thumbnail,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 20),
            Text(book.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (book.subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(book.subtitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ),
            SizedBox(height: 12),
            Text('By: ${book.authors.join(', ')}', style: TextStyle(fontSize: 16)),
            if (book.publisher.isNotEmpty) Text('Publisher: ${book.publisher}', style: TextStyle(fontSize: 16)),
            if (book.publishedDate.isNotEmpty) Text('Published: ${book.publishedDate}', style: TextStyle(fontSize: 16)),
            if (book.pageCount != null) Text('Pages: ${book.pageCount}', style: TextStyle(fontSize: 16)),
            if (book.categories.isNotEmpty)
              Text('Categories: ${book.categories.join(', ')}', style: TextStyle(fontSize: 16)),
            if (book.averageRating != null) Text('Rating: ${book.averageRating} ⭐', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(book.description),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _toggleReadingList,
                icon: Icon(_inReadingList ? Icons.bookmark : Icons.bookmark_border),
                label: Text(_inReadingList ? 'Remove from Reading List' : 'Add to Reading List'),
              ),
            ),
            /* If previewing becomes functional:
            if (book.previewLink.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PreviewPage(previewUrl: book.previewLink),
                    ),
                  );
                },
                child: Text('Preview Book'),
              ),
            */
          ],
        ),
      ),
    );
  }
}
