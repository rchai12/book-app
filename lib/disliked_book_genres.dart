import 'package:flutter/material.dart';
import 'authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DislikedBookGenresPage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const DislikedBookGenresPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  _DislikedBookGenresPageState createState() => _DislikedBookGenresPageState();
}

class _DislikedBookGenresPageState extends State<DislikedBookGenresPage> {
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
  final String _question = 'What are your most disliked book genres?';

  @override
  void initState() {
    super.initState();
    _loadUserGenres();
  }

  void _loadUserGenres() async {
    try {
      List<String> genres = await widget.authService.loadUserDislikedGenres();
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
        widget.authService.updateUserDislikedGenres(_selectedGenres);
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
    // Sort genres alphabetically
    List<String> sortedGenres = List.from(_genres)..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Disliked Genres?!'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Text(
              _question,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Genre Selection Chips
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: sortedGenres.map((genre) {
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
                  selectedColor: Colors.green,
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: _selectedGenres.contains(genre)
                        ? Colors.white
                        : Colors.black,
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            Divider(),

            // Display Selected Genres
            Text(
              'Your selected genres:',
              style: TextStyle(
                fontSize: 18,
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

            // Save Button
            Center(
              child: ElevatedButton(
                onPressed: _saveGenres,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Your Genres',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
