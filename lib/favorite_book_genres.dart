import 'package:flutter/material.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteBookGenresPage extends StatefulWidget {
  User user;
  AuthService authService;

  FavoriteBookGenresPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  _FavoriteBookGenresPageState createState() => _FavoriteBookGenresPageState();
}

class _FavoriteBookGenresPageState extends State<FavoriteBookGenresPage> {
  final List<String> _genres = [
    'Fiction', 'Non-Fiction', 'Mystery', 'Fantasy', 'Science Fiction',
    'Romance', 'Thriller', 'Biography', 'Self-Help', 'Historical Fiction',
    'Adventure', 'Horror', 'Young Adult (YA)', 'Dystopian', 'Poetry',
    'Memoir', 'Crime', 'Psychological Thriller', 'Political Fiction',
    'Magic Realism', 'Literary Fiction', 'Classics', 'Children\'s Fiction',
    'Cookbooks', 'Travel', 'Humor', 'Sports', 'Art', 'Music', 'True Crime',
    'Health & Wellness', 'Philosophy', 'Religion & Spirituality', 'Parenting',
    'Business & Economics', 'Science', 'Mathematics', 'Anthology', 'Graphic Novels',
    'Comics', 'Environmental Fiction', 'Western', 'International',
  ];

  List<String> _selectedGenres = [];
  final String _question = 'What are your favorite book genres?';

  @override
  void initState() {
    super.initState();
    _loadUserGenres();
  }

  void _loadUserGenres() async {
    try {
      List<String> genres = await widget.authService.loadUserFavoriteGenres();
      setState(() {
        _selectedGenres = genres;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load genres: $e'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _saveGenres() {
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one genre'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      setState(() {
        widget.authService.updateUserFavoriteGenres(_selectedGenres);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Genres saved successfully!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Genres?!'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _question,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _genres.map((genre) {
                return ChoiceChip(
                  label: Text(genre),
                  selected: _selectedGenres.contains(genre),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text(
              'Your selected genres:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _selectedGenres.isEmpty
                  ? 'No genres selected'
                  : _selectedGenres.join(', '),
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveGenres,
              child: Text('Save Your Genres'),
            ),
          ],
        ),
      ),
    );
  }
}
