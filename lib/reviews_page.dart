import 'package:flutter/material.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book.dart';
import 'reviews_page_tabs.dart';

class ReviewsPage extends StatelessWidget {
  User user;
  final AuthService authService;

  ReviewsPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Reviews'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Create New Review'),
              Tab(text: 'Past Reviews'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CreateReviewPage(),   // Placeholder for Create New Review page
            PastReviewsPage(user: user, authService: authService,),    // Placeholder for Past Reviews page
          ],
        ),
      ),
    );
  }
}
