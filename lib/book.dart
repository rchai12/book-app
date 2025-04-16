class Book {
  final String id;
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
    required this.id,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'authors': authors,
      'description': description,
      'publisher': publisher,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'categories': categories,
      'averageRating': averageRating,
      'thumbnail': thumbnail,
      'previewLink': previewLink,
      'infoLink': infoLink,
      'language': language,
    };
  }

  factory Book.fromMap(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'] ?? '',
      authors: List<String>.from(json['authors'] ?? []),
      description: json['description'] ?? '',
      publisher: json['publisher'] ?? '',
      publishedDate: json['publishedDate'] ?? '',
      pageCount: json['pageCount'] ?? 0,
      categories: List<String>.from(json['categories'] ?? []),
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
      thumbnail: json['thumbnail'] ?? '',
      previewLink: json['previewLink'] ?? '',
      infoLink: json['infoLink'] ?? '',
      language: json['language'] ?? '',
    );
  }
}
