import 'package:flutter/material.dart';
import 'book.dart';
import 'preview_page.dart';

class BookDetailsPage extends StatelessWidget {
  final Book book;

  const BookDetailsPage({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
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
            Text(
              book.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (book.subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  book.subtitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            SizedBox(height: 12),
            Text('By: ${book.authors.join(', ')}', style: TextStyle(fontSize: 16)),
            if (book.publisher.isNotEmpty)
              Text('Publisher: ${book.publisher}', style: TextStyle(fontSize: 16)),
            if (book.publishedDate.isNotEmpty)
              Text('Published: ${book.publishedDate}', style: TextStyle(fontSize: 16)),
            if (book.pageCount != null)
              Text('Pages: ${book.pageCount}', style: TextStyle(fontSize: 16)),
            if (book.categories.isNotEmpty)
              Text('Categories: ${book.categories.join(', ')}', style: TextStyle(fontSize: 16)),
            if (book.averageRating != null)
              Text('Rating: ${book.averageRating} ⭐', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text(
              'Description',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(book.description),
            SizedBox(height: 20),
            /* Can't get web pages to load in app
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
              ),*/
          ],
        ),
      ),
    );
  }
}
