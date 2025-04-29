import 'package:flutter/material.dart';
import 'book.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_details.dart';
import 'review_edit_dialog.dart';

class ReviewsPage extends StatefulWidget {
  User user;
  final AuthService authService;

  ReviewsPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Reviews'),
      ),
      body: StreamBuilder<List<Book>>(
        stream: widget.authService.getReviewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final _reviewedBooks = snapshot.data ?? [];

          if (_reviewedBooks.isEmpty) {
            return Center(child: Text('No reviews yet.'));
          }
        return ListView.builder(
          itemCount: _reviewedBooks.length,
          itemBuilder: (context, index) {
            final review = _reviewedBooks[index];
            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                // TODO: implement a button to just edit review.
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder:
                //           (_) => ReviewDialogs(
                //               book: review,
                //               user: widget.user,
                //               authService: widget.authService,
                //             ),
                //       ),
                //   );
                // },
                onTap: () {
                    showReviewDialog(
                      context: context,
                      book: review,
                      user: widget.user,
                      authService: widget.authService,
                    );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Thumbnail on the left
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review.thumbnail.isNotEmpty
                            ? review.thumbnail
                            : 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/No_image_available.svg/480px-No_image_available.svg.png',
                          width: 100,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info on the right
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (review.authors as List).join(', '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(5, (i) {
                                int rating =
                                    review.rating ??
                                    0; // Defaults to 0 if review.rating is null
                                return Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review.review ?? 'No review provided',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      ),
    );
  }
}
