import 'package:flutter/material.dart';
import 'book.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showCreateReviewDialog({
  required BuildContext context,
  required Book book,
  required User user,
  required AuthService authService,
  VoidCallback ? onReviewSubmitted,

}) async {
  final parentContext = context;
  final TextEditingController reviewController = TextEditingController();
  int userRating = 0;
  String userReview = '';

  // Show the dialog
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final ScrollController textFieldScrollController = ScrollController();
          return AlertDialog(
            title: Text("Create a Review"),
            content: SizedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Review for: " + book.title,
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
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
                  SizedBox(
                    width: 350,
                    height: 100,
                    child: TextField(
                      controller: reviewController,
                      scrollController: textFieldScrollController,
                      decoration: InputDecoration(
                        hintText: 'Write your review here...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null, // Allow unlimited lines (it will scroll instead of expanding)
                      expands: true, // Makes the TextField fill the parent SizedBox height
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: (value) {
                        userReview = value;
                      },
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  textFieldScrollController.dispose();
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  userReview = reviewController.text;
                  textFieldScrollController.dispose();
                  try {
                    await authService.addBookToReviews(book, userRating, userReview);
                    book.review = userReview;
                    book.rating = userRating;

                    onReviewSubmitted!();
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(parentContext).showSnackBar(
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

void showEditReviewDialog({
  required BuildContext context,
  required Book book,
  required User user,
  required AuthService authService,
  VoidCallback ? onReviewSubmitted,

}) async {
  final TextEditingController reviewController = TextEditingController();
  final parentContext = context;
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

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final ScrollController textFieldScrollController = ScrollController();
          return AlertDialog(
            title: Text("Edit Review"),
            content: SizedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Previous Review for " + book.title + ":",
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (i) {
                      int rating =
                          userRating;
                      return Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  SizedBox(height: 8),
                  Text(
                    book.review ?? "",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 14),
                  Text(
                    "New Review:",
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
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
                  SizedBox(
                    width: 350,
                    height: 100,
                    child: TextField(
                      controller: reviewController,
                      scrollController: textFieldScrollController,
                      decoration: InputDecoration(
                        hintText: 'Write your review here...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: (value) {
                        userReview = value;
                      },
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              
              TextButton(
                onPressed: () {
                  textFieldScrollController.dispose();
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  userReview = reviewController.text;
                  textFieldScrollController.dispose();
                  try {
                    await authService.addBookToReviews(book, userRating, userReview);
                    book.review = userReview;
                    book.rating = userRating;

                    onReviewSubmitted!();
                    Navigator.of(context).pop();
                    
                    ScaffoldMessenger.of(parentContext).showSnackBar(
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
