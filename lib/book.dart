class Book {
  final String title;
  final String subtitle;
  final List<String> authors;
  final String description;
  final String publisher;
  final String publishedDate;
  final int pageCount;
  final List<String> categories;
  final double averageRating;
  final String thumbnail;
  final String previewLink;
  final String infoLink;
  final String language;

  Book({
    required this.title,
    required this.subtitle,
    required this.authors,
    required this.description,
    required this.publisher,
    required this.publishedDate,
    required this.pageCount,
    required this.categories,
    required this.averageRating,
    required this.thumbnail,
    required this.previewLink,
    required this.infoLink,
    required this.language,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};

    return Book(
      title: volumeInfo['title'] ?? 'No Title',
      subtitle: volumeInfo['subtitle'] ?? '',
      authors: (volumeInfo['authors'] as List?)?.map((e) => e.toString()).toList() ?? ['Unknown'],
      description: volumeInfo['description'] ?? '',
      publisher: volumeInfo['publisher'] ?? '',
      publishedDate: volumeInfo['publishedDate'] ?? '',
      pageCount: volumeInfo['pageCount'] ?? 0,
      categories: (volumeInfo['categories'] as List?)?.map((e) => e.toString()).toList() ?? [],
      averageRating: (volumeInfo['averageRating'] ?? 0).toDouble(),
      thumbnail: volumeInfo['imageLinks']?['thumbnail'] ?? '',
      previewLink: volumeInfo['previewLink'] ?? '',
      infoLink: volumeInfo['infoLink'] ?? '',
      language: volumeInfo['language'] ?? '',
    );
  }
}
