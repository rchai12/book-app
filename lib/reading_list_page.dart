import 'package:flutter/material.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'book.dart';
import 'reading_status.dart';
import 'reading_status_page.dart';

class ReadingListPage extends StatelessWidget {
  final User user;
  final AuthService authService;

  const ReadingListPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Reading List'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Plan to Read'),
              Tab(text: 'Currently Reading'),
              Tab(text: 'Finished'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ReadingStatusPage(status: ReadingStatus.wantToRead, user: user, authService: authService),
            ReadingStatusPage(status: ReadingStatus.currentlyReading, user: user, authService: authService),
            ReadingStatusPage(status: ReadingStatus.finished, user: user, authService: authService),
          ],
        ),
      ),
    );
  }
}
