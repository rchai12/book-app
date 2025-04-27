import 'package:flutter/material.dart';
import 'book.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Placeholder widget for "Create New Review" tab
class CreateReviewPage extends StatelessWidget {
  const CreateReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Create a new review here.'));
  }
}

// Placeholder widget for "Past Reviews" tab
class PastReviewsPage extends StatefulWidget {
  User user;
  final AuthService authService;

  PastReviewsPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<PastReviewsPage> createState() => _PastReviewsPageState();
}

class _PastReviewsPageState extends State<PastReviewsPage> {
  List<Book> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    try {
      final reviews = await widget.authService.getReviews();

      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        itemCount: _reviews.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1, // 1 card per row
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6, // Adjust height vs width ratio
        ),
        itemBuilder: (context, index) {
          final review = _reviews[index];

          return Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Thumbnail on the left
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review.thumbnail,
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
                            int rating = review.rating ?? 0;  // Defaults to 0 if review.rating is null
                            return Icon(
                              i < rating
                                  ? Icons.star
                                  : Icons.star_border,
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
          );
        },
      ),
    );
  }
}
