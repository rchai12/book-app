import 'package:flutter/material.dart';
import 'book.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reading_status.dart';
import 'ai_api.dart';

class BookDetailsPage extends StatefulWidget {
  final Book book;
  final User user;
  final AuthService authService;

  const BookDetailsPage({
    super.key,
    required this.book,
    required this.user,
    required this.authService,
  });

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  bool _isFavorited = false;
  bool _inReadingList = false;
  int _userRating = 0;
  String _userReview = '';
  final _reviewController = TextEditingController();
  final AIRecommendationService _aiService = AIRecommendationService();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _checkReadingListStatus();
    _checkBookReview();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await widget.authService.isBookInFavorites(widget.book.id);
    setState(() {
      _isFavorited = isFavorite;
    });
  }

  Future<void> _checkReadingListStatus() async {
    final isInList = await widget.authService.isBookInReadingList(widget.book.id);
    setState(() {
      _inReadingList = isInList;
    });
  }

  void _checkBookReview() async {
    try {
      print('Checking if has review');
      final reviewData = await widget.authService.getBookReview(widget.book.id);
      if (reviewData != null) {
        setState(() {
          _userRating = reviewData['rating'];
          _userReview = reviewData['review'];
          widget.book.rating = _userRating;
          widget.book.review = _userReview;
          print('Review: $_userReview');
          print ('Rating: $_userRating');
        });
      }
    } catch (e) {
      print('Error checking book review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to retrieve review. Please try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleFavorite() async {
    if (_isFavorited) {
      await widget.authService.removeBookFromFavorites(widget.book.id);
    } else {
      await widget.authService.addBookToFavorites(widget.book);
    }
    setState(() {
      _isFavorited = !_isFavorited;
    });
  }

  void _toggleReadingList() async {
    if (_inReadingList) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This book is already in your reading list.'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      await widget.authService.addBookToReadingList(
        book: widget.book,
        status: ReadingStatus.wantToRead,
      );
      setState(() {
        _inReadingList = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book added to your reading list.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _submitReview() async {
    try {
      await widget.authService.addBookToReviews(widget.book, _userRating, _userReview,);
      setState(() {
        widget.book.review = _userReview;
        widget.book.rating = _userRating;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review added successfully!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _removeUserReview() async {
    try {
      await widget.authService.removeBookFromReviews(widget.book.id);
      setState(() {
        _userReview = '';
        _userRating = 0;
      });
    } catch (e) {
      print('Error removing review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove review.')),
      );
    }
  }


  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _userRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _userRating = index + 1;
            });
          },
        );
      }),
    );
  }

  Future<void> analyzeBook() async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final analysis = await _aiService.getBookAnalysis(widget.book);
      print(analysis);
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Book Analysis'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: parseAnalysis(analysis),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      print('Error analyzing book: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to analyze the book. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  List<Widget> parseAnalysis(String markdown) {
    final lines = markdown.split('\n');
    List<Widget> widgets = [];
    String? currentTitle;
    StringBuffer currentContent = StringBuffer();
    for (var line in lines) {
      if (line.startsWith('**')) {
        if (currentTitle != null && currentContent.isNotEmpty) {
          widgets.add(_buildSection(currentTitle, currentContent.toString()));
        }
        currentTitle = line.replaceFirst('**', '').replaceFirst('**', '').trim();
        currentContent.clear();
      } else if (line.trim().isNotEmpty) {
        currentContent.writeln(line.trim());
      }
    }
    if (currentTitle != null && currentContent.isNotEmpty) {
      widgets.add(_buildSection(currentTitle, currentContent.toString()));
    }
    return widgets;
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        backgroundColor: Colors.lightGreen,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
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
            Text(book.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (book.subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(book.subtitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ),
            SizedBox(height: 12),
            Text('By: ${book.authors.join(', ')}', style: TextStyle(fontSize: 16)),
            if (book.publisher.isNotEmpty) Text('Publisher: ${book.publisher}', style: TextStyle(fontSize: 16)),
            if (book.publishedDate.isNotEmpty) Text('Published: ${book.publishedDate}', style: TextStyle(fontSize: 16)),
            Text('Pages: ${book.pageCount}', style: TextStyle(fontSize: 16)),
            if (book.categories.isNotEmpty)
              Text('Categories: ${book.categories.join(', ')}', style: TextStyle(fontSize: 16)),
            Text('Rating: ${book.averageRating} ⭐', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(book.description),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => analyzeBook(),
                icon: Icon(Icons.auto_awesome),
                label: Text('Analyze Book (AI)'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.teal,
                ),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _toggleReadingList,
                icon: Icon(_inReadingList ? Icons.bookmark : Icons.bookmark_border),
                label: Text(_inReadingList ? 'Remove from Reading List' : 'Add to Reading List'),
              ),
            ),
            if (_userReview.isNotEmpty && _userRating > 0)
              Dismissible(
                key: Key('user_review_${widget.book.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await _removeUserReview();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Review removed.')),
                  );
                },
                child: Container( // <<--- ADD THIS CONTAINER
                  width: double.infinity, // <<--- FORCE FULL WIDTH
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Review:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(_userReview),
                      SizedBox(height: 10),
                      Text('Your Rating: $_userRating/5 stars'),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 30),
            Text('Rate this book:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildRatingStars(),
            Text('Add a Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: 'Write your review here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: (value) {
                setState(() {
                  _userReview = value;
                });
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitReview,
              child: Text('Submit Review'),
            ),
            /* If previewing becomes functional, can't get it to work with in app web viewing:
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
              ),
            */
          ],
        ),
      ),
    );
  }
}
