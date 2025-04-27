import 'package:flutter/material.dart';
import 'book.dart';
import 'authentication.dart';
import 'book_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reading_status.dart';

// Placeholder widget for "Create New Review" tab
class CreateReviewPage extends StatelessWidget {
  const CreateReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Create a new review here.'),
    );
  }
}

// Placeholder widget for "Past Reviews" tab
class PastReviewsPage extends StatelessWidget {
  const PastReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Past reviews will be shown here.'),
    );
  }
}