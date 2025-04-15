import 'package:flutter/material.dart';
import 'google_books_api.dart';
import 'book.dart';

class BookSearchPage extends StatefulWidget {
  @override
  _BookSearchPageState createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<Book> _books = [];
  bool _loading = false;

  void _search() async {
    setState(() => _loading = true);
    try {
      final results = await GoogleBooksApi.searchBooks(_controller.text);
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
      appBar: AppBar(title: Text('Books Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search our Books!',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return ListTile(
                          leading: book.thumbnail.isNotEmpty
                              ? Image.network(book.thumbnail, width: 50, fit: BoxFit.cover)
                              : null,
                          title: Text(book.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (book.subtitle.isNotEmpty) Text(book.subtitle, style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(book.authors.join(', ')),
                              if (book.publisher.isNotEmpty) Text('Published by ${book.publisher}'),
                            ],
                          ),
                          onTap: () {
                            if (book.previewLink.isNotEmpty) {
                              // placeholder to go to book details page
                            }
                          },
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
