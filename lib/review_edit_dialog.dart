import 'package:flutter/material.dart';
import 'book.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showReviewDialog({
  required BuildContext context,
  required Book book,
  required User user,
  required AuthService authService,
}) async {
  final TextEditingController reviewController = TextEditingController();
  int userRating = 0;
  String userReview = '';

  // Load existing review if available
  try {
    final reviewData = await authService.getBookReview(book.id);
    if (reviewData != null) {
      userRating = reviewData['rating'];
      userReview = reviewData['review'];
      book.rating = userRating;
      book.review = userReview;
      reviewController.text = userReview;
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to retrieve review. Please try again later.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Show the dialog
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Edit Review"),
            content: SizedBox(
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Past Review:"),
                  SizedBox(height: 4),
                  Text(
                    book.review ?? '',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 10),
                  Text("New Rating:"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < userRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            userRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: reviewController,
                    decoration: InputDecoration(
                      hintText: 'Write your review here...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      userReview = value;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  userReview = reviewController.text;
                  Navigator.of(context).pop();
                  try {
                    await authService.addBookToReviews(book, userRating, userReview);
                    book.review = userReview;
                    book.rating = userRating;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Review submitted successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit review. Please try again.')),
                    );
                  }
                },
                child: Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );
}
