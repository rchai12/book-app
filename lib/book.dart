import 'reading_status.dart';

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
  bool? favorite;
  bool? readingList;
  bool? reviewed;
  ReadingStatus? readingStatus;
  String? review;
  int? rating;

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
    this.favorite,
    this.readingList,
    this.reviewed,
    this.readingStatus,
    this.review,
    this.rating,
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
      'favorite': favorite,
      'reading_list': readingList,
      'reviewed': reviewed,
      'reading_status': readingStatus?.name,
      'review': review,
      'rating': rating,
    };
  }

  factory Book.fromMap(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};

    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Untitled',
      subtitle: volumeInfo['subtitle'] ?? '',
      authors: List<String>.from(volumeInfo['authors'] ?? ['Unknown']),
      description: volumeInfo['description'] ?? '',
      publisher: volumeInfo['publisher'] ?? '',
      publishedDate: volumeInfo['publishedDate'] ?? '',
      pageCount: volumeInfo['pageCount'] ?? 0,
      categories: List<String>.from(volumeInfo['categories'] ?? []),
      averageRating: (volumeInfo['averageRating'] != null)
          ? (volumeInfo['averageRating'] as num).toDouble()
          : 0.0,
      thumbnail: imageLinks['thumbnail'] ?? '',
      previewLink: volumeInfo['previewLink'] ?? '',
      infoLink: volumeInfo['infoLink'] ?? '',
      language: volumeInfo['language'] ?? '',
      favorite: json['favorite'] == true,
      readingList: json['reading_list'] == true,
      reviewed: json['reviewed'] == true,
      readingStatus: json['reading_status'] != null
          ? ReadingStatus.values.firstWhere(
              (e) => e.name == json['reading_status'],
              orElse: () => ReadingStatus.wantToRead,
            )
          : null,
      review: json['review'],
      rating: json['rating'],
    );
  }

  factory Book.fromFirestore(Map<String, dynamic> data) {
    return Book(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Untitled',
      subtitle: data['subtitle'] ?? '',
      authors: List<String>.from(data['authors'] ?? ['Unknown']),
      description: data['description'] ?? '',
      publisher: data['publisher'] ?? '',
      publishedDate: data['publishedDate'] ?? '',
      pageCount: data['pageCount'] ?? 0,
      categories: List<String>.from(data['categories'] ?? []),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      thumbnail: data['thumbnail'] ?? '',
      previewLink: data['previewLink'] ?? '',
      infoLink: data['infoLink'] ?? '',
      language: data['language'] ?? '',
      favorite: data['favorite'] == true,
      readingList: data['reading_list'] == true,
      reviewed: data['reviewed'] == true,
      readingStatus: data['reading_status'] != null
        ? ReadingStatus.values.firstWhere(
            (e) => e.name == data['reading_status'],
            orElse: () => ReadingStatus.wantToRead,
          )
        : null,
      review: data['review'],
      rating: data['rating'],
    );
  }
}
