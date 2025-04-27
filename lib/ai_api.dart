import 'package:google_generative_ai/google_generative_ai.dart';
import 'book.dart';

class AIRecommendationService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: 'AIzaSyDYnaotthPtFO3gArWCHqGbrviybJCYRvw',
  );

  Future<List<String>> getBookRecommendations({
    required List<Book> books,
    required List<String> likedGenres,
    required List<String> dislikedGenres,
  }) async {
    final prompt = _buildPrompt(books, likedGenres, dislikedGenres);
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      print('Recommendations received');
      final text = response.text ?? "";
      final titles = text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
      return titles;
    } catch (e) {
      print('AI Recommendation Error: $e');
      return [];
    }
  }

  String _buildPrompt(List<Book> books, List<String> likedGenres, List<String> dislikedGenres) {
    final buffer = StringBuffer();

    buffer.writeln("You are a book recommendation assistant. Given a user's book history and preferences, suggest a new book they might like. Prioritize books that have high ratings and strong reviews, followed by finished and favorited books, followed by favorited books, followed by currently reading books, then their liked and disliked genres, and finally books marked as 'want to read'. Do not recommend books already on the user's list!");
    buffer.writeln("\nHere is the user's data:");

    for (final book in books) {
      buffer.writeln("\n- Title: ${book.title}");
      buffer.writeln("  Category: ${book.categories}");
      buffer.writeln("  Favorite: ${book.favorite}");
      buffer.writeln("  Reading List: ${book.readingList}");
      buffer.writeln("  Reading Status: ${book.readingStatus.toString().split('.').last}");
      buffer.writeln("  Rating: ${book.rating ?? 'N/A'}");
      buffer.writeln("  Review: ${book.review ?? 'N/A'}");
    }

    buffer.writeln("\nLiked Genres: ${likedGenres.join(', ')}");
    buffer.writeln("Disliked Genres: ${dislikedGenres.join(', ')}");

    buffer.writeln("\nBased on the above data, recommend 10 books and explain why it fits the user's preferences.");

    return buffer.toString();
  }

  Future<String> getBookAnalysis(Book book) async {
    final prompt = '''
    You are an expert book reviewer. 
    Analyze the book "${book.title}" by ${book.authors.join(', ')}.

    Please organize your response into the following sections:
    - **Writing Quality** followed by your opinion on the writing quality in a clear, concise paragraph.
    - **Common Praise** followed by your opinion on common praise of the book in a clear, concise paragraph.
    - **Common Criticism** followed by your opinion on common criticism of the book in a clear, concise paragraph.
    - **Other Notes** followed by any other relevant thoughts on the book.

    Do not use bullet points. Please ensure that each section starts with a bold title (e.g., **Writing Quality**) followed by the content on a new line.

    Use clear and concise language. 
    Only return the markdown text. Do not include anything else.

    If you don't know something, you can say "Information not widely available."
    ''';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      print('Analysis received for book: ${book.title}');
      return response.text ?? "";
    } catch (e) {
      print('AI Analysis Error: $e');
      return "Failed to analyze the book.";
    }
  }
}
