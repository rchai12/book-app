import 'package:flutter/material.dart';
import 'google_books_api.dart';
import 'book.dart';
import 'book_details.dart';

class TrendingBooksPage extends StatefulWidget {
  @override
  _TrendingBooksPageState createState() => _TrendingBooksPageState();
}

class _TrendingBooksPageState extends State<TrendingBooksPage> {
  List<Book> _books = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchTrendingBooks();
  }

  void _fetchTrendingBooks() async {
    setState(() => _loading = true);
    
    try {
      final results = await GoogleBooksApi.searchBooks('bestsellers OR trending OR new releases');
      setState(() => _books = results);
    } catch (e) {
      print(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trending Books')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _loading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: book.thumbnail.isNotEmpty
                                ? Image.network(book.thumbnail, width: 80, fit: BoxFit.cover)
                                : null,
                            title: Text(book.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (book.subtitle.isNotEmpty)
                                  Text(book.subtitle, style: TextStyle(fontWeight: FontWeight.w500)),
                                Text(book.authors.join(', ')),
                                if (book.publisher.isNotEmpty)
                                  Text('Published by ${book.publisher}'),
                              ],
                            ),
                            onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookDetailsPage(book: book),
                                  ),
                                );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
