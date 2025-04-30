import 'package:flutter/material.dart';
import 'book.dart';
import 'authentication.dart';
import 'ai_api.dart';
import 'google_books_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reading_status.dart';
import 'book_details.dart';

class RecommendedPage extends StatefulWidget {
  final User user;
  final AuthService authService;
  
  const RecommendedPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<RecommendedPage> createState() => _RecommendedPageState();
}

class _RecommendedPageState extends State<RecommendedPage> {
  final AIRecommendationService _aiService = AIRecommendationService();
  List<Book> _recommendedBooks = [];
  bool _loading = true;
  bool _loadingRecommendations = true;
  Set<String> _favoriteIds = {};
  Set<String> _readingListIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final books = await widget.authService.getBooks();
      final likedGenres = await widget.authService.loadUserFavoriteGenres();
      final dislikedGenres = await widget.authService.loadUserDislikedGenres();
      final recommendations = await _aiService.getBookRecommendations(
        books: books,
        likedGenres: likedGenres,
        dislikedGenres: dislikedGenres,
      );
      setState(() {
        _loadingRecommendations = false;
      });
      final favorites = await widget.authService.getFavorites();
      final readingList = await widget.authService.getReadingList();
      List<Book> fetchedBooks = [];
      for (final title in recommendations) {
        final results = await GoogleBooksApi.searchBooks(title, maxResults: 1);
        if (results.isNotEmpty) {
          fetchedBooks.add(results.first);
        }
      }
      setState(() {
        _recommendedBooks = fetchedBooks;
        _favoriteIds = favorites.map((book) => book.id).toSet();
        _readingListIds = readingList.map((book) => book.id).toSet();
        _loading = false;
      });
    } catch (e) {
      print('Error fetching recommendations: $e');
      setState(() {
        _loading = false;
        _loadingRecommendations = false;
      });
    }
  }

  void _toggleFavorite(Book book) async {
    if (_favoriteIds.contains(book.id)) {
      await widget.authService.removeBookFromFavorites(book.id);
      setState(() {
        _favoriteIds.remove(book.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.title} removed from Favorites!'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      await widget.authService.addBookToFavorites(book);
      setState(() {
        _favoriteIds.add(book.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.title} added to Favorites!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleAddToReadingList(Book book) async {
    if (_readingListIds.contains(book.id)) {
      await widget.authService.removeBookFromReadingList(book.id);
      setState(() {
        _readingListIds.remove(book.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.title} removed from reading list!'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      await widget.authService.addBookToReadingList(
        book: book,
        status: ReadingStatus.wantToRead,
      );
      setState(() {
        _readingListIds.add(book.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.title} added to reading list!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Recommended Books', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    _loadingRecommendations
                        ? 'Asking AI, please wait a bit!'
                        : 'Got the recommendations, searching for the books!',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            )
          : _recommendedBooks.isEmpty
              ? const Center(child: Text('No recommendations available.\nPlease make sure you have selected\nyour favorite and disliked genres\nin the Profile Page.'))
              : PageView.builder(
                itemCount: _recommendedBooks.length,
                controller: PageController(viewportFraction: 0.85),
                itemBuilder: (context, index) {
                  final book = _recommendedBooks[index];
                  final isFavorite = _favoriteIds.contains(book.id);
                  final isInReadingList = _readingListIds.contains(book.id);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookDetailsPage(
                                book: book,
                                user: widget.user,
                                authService: widget.authService,
                              ),
                            ),
                          );
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  child: Image.network(
                                    book.thumbnail,
                                    height: constraints.maxHeight * 0.72,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: constraints.maxHeight * 0.72,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.book, size: 80),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title,
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          book.authors.join(', '),
                                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                                color: isFavorite ? Colors.red : Colors.black,
                                              ),
                                              onPressed: () => _toggleFavorite(book),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isInReadingList ? Icons.bookmark : Icons.bookmark_outline,
                                                color: Colors.black,
                                              ),
                                              tooltip: isInReadingList
                                                  ? 'Already in Reading List'
                                                  : 'Read Later',
                                              onPressed: () => _handleAddToReadingList(book),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              )
    );
  }
}