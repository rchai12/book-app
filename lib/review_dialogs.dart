import 'package:flutter/material.dart';
import 'book.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_details.dart';

class ReviewDialogs {
  // Method to show a dialog to made new reviews
  static void showMakeNewReviewDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    Function()? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                if (onPressed != null) {
                  onPressed();
                }
                Navigator.of(context).pop();
              },
              child: Text(buttonText ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

  // Method to show a dialog to edit already made reviews
  static void showEditReviewDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Function() onConfirm,
    Function()? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onCancel != null) {
                  onCancel();
                }
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
