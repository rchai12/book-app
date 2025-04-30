import 'package:flutter/material.dart';
import 'google_books_api.dart';
import 'book.dart';
import 'book_details.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reading_status.dart';
import 'review_dialogs.dart';

class TrendingBooksPage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const TrendingBooksPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  _TrendingBooksPageState createState() => _TrendingBooksPageState();
}

class _TrendingBooksPageState extends State<TrendingBooksPage> {
  List<Book> _books = [];
  bool _loading = false;
  Set<String> _favoriteIds = {};
  Set<String> _reviewedIds = {};
  Set<String> _readingListIds = {};
  int _startIndex = 0;
  final int _maxResults = 10;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchTrendingBooks();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _hasMore &&
        !_loading) {
      _fetchTrendingBooks(loadMore: true);
    }
  }

  void _fetchTrendingBooks({bool loadMore = false}) async {
    if (loadMore) _isFetchingMore = true;
    setState(() => _loading = true);

    try {
       final results = await GoogleBooksApi.searchBooks(
        'new+arrivals',
        startIndex: _startIndex,
        maxResults: _maxResults,
        orderBy: 'relevance',
      );
      final favorites = await widget.authService.getFavorites();
      final reviewed = await widget.authService.getReviewedList();
      final readingList = await widget.authService.getReadingList();
      setState(() {
        if (loadMore) {
          _books.addAll(results);
        } else {
          _books = results;
        }
        _startIndex += _maxResults;
        _hasMore = results.length == _maxResults;
        _favoriteIds = favorites.map((book) => book.id).toSet();
        _reviewedIds = reviewed.map((book) => book.id).toSet();
        _readingListIds = readingList.map((book) => book.id).toSet();
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() => _loading = false);
      _isFetchingMore = false;
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
      appBar: AppBar(title: Text('Trending Books')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (!_loading &&
                      _hasMore &&
                      scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                    _fetchTrendingBooks(); // Load more
                  }
                  return false;
                },
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: _books.length + (_loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _books.length && _loading) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final book = _books[index];
                    final isFavorite = _favoriteIds.contains(book.id);
                    final isReviewed = _reviewedIds.contains(book.id);
                    return Card(
                      elevation: 5,
                      child: InkWell(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (book.thumbnail.isNotEmpty)
                              Image.network(
                                book.thumbnail,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                book.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                book.authors.join(', '),
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : null,
                                    ),
                                    onPressed: () => _toggleFavorite(book),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isReviewed
                                          ? Icons.star
                                          : Icons.star_border_outlined,
                                      color: isReviewed ? Colors.amber : null,
                                    ),
                                    tooltip:
                                        isReviewed
                                            ? 'Edit Review'
                                            : 'Create a Review',
                                    onPressed: () {
                                      final showDialogFn =
                                          isReviewed
                                              ? showEditReviewDialog
                                              : showCreateReviewDialog;
                                      showDialogFn(
                                        context: context,
                                        book: book,
                                        user: widget.user,
                                        authService: widget.authService,
                                        onReviewSubmitted: () async {
                                          final reviewed =
                                              await widget.authService
                                                  .getReviewedList();
                                          setState(() {
                                            _reviewedIds =
                                                reviewed
                                                    .map((b) => b.id)
                                                    .toSet();
                                          });
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _readingListIds.contains(book.id)
                                          ? Icons.bookmark
                                          : Icons.bookmark_outline,
                                    ),
                                    tooltip: _readingListIds.contains(book.id)
                                        ? 'Already in Reading List'
                                        : 'Read Later',
                                    onPressed: () => _handleAddToReadingList(book),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
