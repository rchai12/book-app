import 'package:flutter/material.dart';
import 'google_books_api.dart';
import 'book.dart';
import 'book_details.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reading_status.dart';
import 'edit_review_dialog.dart';
import 'create_review_dialog.dart';

class BookSearchPage extends StatefulWidget {
  User user;
  final AuthService authService;

  BookSearchPage({super.key, required this.user, required this.authService});
  @override
  _BookSearchPageState createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<Book> _books = [];
  bool _loading = false;
  Set<String> _favoriteIds = {};
  Set<String> _readingListIds = {};
  Set<String> _reviewedIds = {};
  int _startIndex = 0;
  final int _maxResults = 10;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final List<String> _genres = [
    'Fiction',
    'Non-Fiction',
    'Mystery',
    'Fantasy',
    'Science Fiction',
    'Romance',
    'Thriller',
    'Biography',
    'Self-Help',
    'Historical Fiction',
    'Adventure',
    'Horror',
    'Young Adult (YA)',
    'Dystopian',
    'Poetry',
    'Memoir',
    'Crime',
    'Psychological Thriller',
    'Political Fiction',
    'Magic Realism',
    'Literary Fiction',
    'Classics',
    'Children\'s Fiction',
    'Cookbooks',
    'Travel',
    'Humor',
    'Sports',
    'Art',
    'Music',
    'True Crime',
    'Health & Wellness',
    'Philosophy',
    'Religion & Spirituality',
    'Parenting',
    'Business & Economics',
    'Science',
    'Mathematics',
    'Anthology',
    'Graphic Novels',
    'Comics',
    'Environmental Fiction',
    'Western',
    'International',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (_hasMore && !_loading) _search(isNewSearch: false);
      }
    });
    _controller.text = "best+sellers";
    _search();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _search({bool isNewSearch = true}) async {
    print("Search triggered");
    print('Loading is: $_loading\nHasMore is: $_hasMore');
    if (_loading || !_hasMore) return;
    print("Search Query: ${_controller.text}");
    setState(() => _loading = true);
    try {
      if (isNewSearch) {
        _startIndex = 0;
        _hasMore = true;
        _books.clear();
      }
      final results = await GoogleBooksApi.searchBooks(
        _controller.text,
        startIndex: _startIndex,
        maxResults: _maxResults,
      );
      print("Search results count: ${results.length}");
      if (results.length < _maxResults && results.isNotEmpty) {
        _startIndex += results.length;
      } else {
        _startIndex += _maxResults;
      }
      final favorites = await widget.authService.getFavorites();
      final readingList = await widget.authService.getReadingList();
      final reviewed = await widget.authService.getReviewedList();
      setState(() {
        if (isNewSearch) {
          _books = results.isNotEmpty ? results : [];
        } else {
          final existingIds = _books.map((b) => b.id).toSet();
          final newBooks =
              results.where((b) => !existingIds.contains(b.id)).toList();
          _books.addAll(newBooks);
        }
        _favoriteIds = favorites.map((book) => book.id).toSet();
        _readingListIds = readingList.map((book) => book.id).toSet();
        _reviewedIds = reviewed.map((book) => book.id).toSet();
        _hasMore = results.length >= _maxResults;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() => _loading = false);
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Genre'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _genres.map(_buildGenreOption).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenreOption(String genre) {
    return ListTile(
      title: Text(genre),
      onTap: () {
        Navigator.pop(context);
        _controller.clear();
        _controller.text = 'subject:$genre';
        setState(() {
          _hasMore = true;
        });
        _search(isNewSearch: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _controller,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Search for Books',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _hasMore = true;
                  });
                  _search(isNewSearch: true);
                },
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (!_loading &&
                      _hasMore &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                    _search(isNewSearch: false);
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
                    final isReadingList = _readingListIds.contains(book.id);
                    final isReviewed = _reviewedIds.contains(book.id);
                    return Card(
                      elevation: 5,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => BookDetailsPage(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                book.authors.join(', '),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
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
                                      final callback = () async {
                                        final reviewed =
                                            await widget.authService
                                                .getReviewedList();
                                        setState(() {
                                          _reviewedIds =
                                              reviewed.map((b) => b.id).toSet();
                                        });
                                      };
                                      isReviewed
                                      ? showEditReviewDialog(
                                        context: context,
                                        book: book,
                                        user: widget.user,
                                        authService: widget.authService,
                                        onReviewSubmitted: callback)
                                      : showCreateReviewDialog(
                                        context: context,
                                        book: book,
                                        user: widget.user,
                                        authService: widget.authService,
                                        onReviewSubmitted: callback);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isReadingList
                                          ? Icons.bookmark
                                          : Icons.bookmark_outline,
                                    ),
                                    tooltip:
                                        isReadingList
                                            ? 'Already in Reading List'
                                            : 'Read Later',
                                    onPressed:
                                        () => _handleAddToReadingList(book),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 172, 190, 221),
        child: Icon(Icons.filter_list),
        tooltip: 'Filter by Genre',
        onPressed: _showFilterDialog,
      ),
    );
  }
}
