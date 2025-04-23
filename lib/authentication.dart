import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message.dart';
import 'book.dart';
import 'reading_status.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerUser({
    required String name,
    required String email,
    required String password,
    required DateTime dateOfBirth,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'date_of_birth': Timestamp.fromDate(dateOfBirth),
          'created_at': Timestamp.now(),
          'role' : 'user'
        });
        await user.updateDisplayName(name);
        await user.reload();
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload();

      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
      });
    }
  }

  Future<void> updatePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        await user.reload();
        print('Password updated successfully');
      } on FirebaseAuthException catch (e) {
        throw Exception('Password update failed: ${e.message}');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<User?> updateEmail({
    required String email,
    required String currentPassword,
    required String newEmail,
  }) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.verifyBeforeUpdateEmail(newEmail);
        await _auth.currentUser!.reload();
        print('New Email: ${_auth.currentUser!.email}');
        return _auth.currentUser;
      } on FirebaseAuthException catch (e) {
        throw Exception('Email update failed: ${e.message}');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        return await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
      } catch (e) {
        throw Exception('Error fetching user data: $e');
      }
    } else {
      return null;
    }
  }

  Future<void> updateName(String newName) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updateProfile(displayName: newName);
        await user.reload();

        print('Name updated successfully');
      } on FirebaseAuthException catch (e) {
        throw Exception('Failed to update name: ${e.message}');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<List<Message>> getUserMessages(String userId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> messageSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('messages')
          .orderBy('timestamp')
          .get();
      List<Message> messages = messageSnapshot.docs.map((doc) {
        return Message.fromDoc(doc);
      }).toList();
      return messages;
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  Future<void> addMessageToCollection({
    required String userId,
    required String sender,
    required String text,
    required String messageBoardId,
  }) async {
    try {
      Timestamp timestamp = Timestamp.now();
      final messageId = FirebaseFirestore.instance.collection('tmp').doc().id;
      Message message = Message(
        id: messageId,
        text: text,
        sender: sender,
        userId: userId,
        timestamp: timestamp,
        messageBoardId: messageBoardId,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());
      await FirebaseFirestore.instance
          .collection('messageboard')
          .doc(messageBoardId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());
    } catch (e) {
      throw Exception('Error adding message: $e');
    }
  }

  Future<List<Message>> getMessagesFromCollection({required String messageBoardId}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('messageboard')
          .doc(messageBoardId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();
      List<Message> messages = snapshot.docs.map((doc) {
        return Message.fromDoc(doc);
      }).toList();
      return messages;
    } catch (e) {
      throw Exception('Error retrieving messages: $e');
    }
  }

  Future<String> createMessageBoard({
    required String title,
    required String createdByUserId,
    required String imageUrl,
  }) async {
    try {
      DocumentReference messageBoardRef =
          FirebaseFirestore.instance.collection('messageboard').doc();
      await messageBoardRef.set({
        'title': title,
        'created_by': createdByUserId,
        'created_at': Timestamp.now(),
        'image' : imageUrl,
      });
      return messageBoardRef.id;
    } catch (e) {
      throw Exception('Error creating message board: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllMessageBoards() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('messageboard')
          .orderBy('created_at', descending: true)
          .get();
      List<Map<String, dynamic>> boards = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; 
        return data;
      }).toList();
      return boards;
    } catch (e) {
      throw Exception('Error retrieving message boards: $e');
    }
  }

  Future<void> deleteMessageBoard(String messageBoardId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> messagesSnapshot = await FirebaseFirestore.instance
          .collection('messageboard')
          .doc(messageBoardId)
          .collection('messages')
          .get();
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }
      await FirebaseFirestore.instance
          .collection('messageboard')
          .doc(messageBoardId)
          .delete();
      print("Message board and all its messages deleted successfully");
    } catch (e) {
      throw Exception('Error deleting message board: $e');
    }
  }

  Future<void> deleteMessage({
    required String messageBoardId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('messageboard')
          .doc(messageBoardId)
          .collection('messages')
          .doc(messageId)
          .delete();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('messages')
          .doc(messageId)
          .delete();
      print('Message deleted from message board.');
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }

  Future<void> addBookToFavorites(Book book) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference bookDocRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('books')
            .doc(book.id);
        DocumentSnapshot docSnapshot = await bookDocRef.get();
        if (docSnapshot.exists) {
          await bookDocRef.update({'favorite': true});
          print('Book marked as favorite.');
        } else {
          await bookDocRef.set({
            'id': book.id,
            'favorite': true,
          });
          print('Book added with favorite = true.');
        }
      } catch (e) {
        print('Error adding book to favorites: $e');
        throw Exception('Failed to update favorite status.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<void> removeBookFromFavorites(String bookId) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }
    try {
      DocumentReference bookDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('books')
          .doc(bookId);
      DocumentSnapshot docSnapshot = await bookDocRef.get();
      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;
        bool isReadingList = data['reading_list'] ?? false;
        bool isReviewed = data['reviewed'] ?? false;
        if (!isReadingList && !isReviewed) {
          await bookDocRef.delete();
          print('Book removed entirely from user collection.');
        } else {
          await bookDocRef.update({'favorite': false});
          print('Book favorite status set to false.');
        }
      } else {
        print('Book not found in user\'s books collection.');
      }
    } catch (e) {
      print('Error updating favorite status: $e');
      throw Exception('Failed to update favorite status.');
    }
  }



  Future<List<String>> getFavorites() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }
    try {
      CollectionReference booksRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('books');
      QuerySnapshot querySnapshot = await booksRef
          .where('favorite', isEqualTo: true)
          .get();
      List<String> favoriteBookIds = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['id'] as String;
      }).toList();
      return favoriteBookIds;
    } catch (e) {
      print('Error retrieving favorites: $e');
      throw Exception('Failed to retrieve favorites.');
    }
  }


  Future<void> addBookToReadingList({
    required Book book,
    required ReadingStatus status,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }
    try {
      DocumentReference bookDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('books')
          .doc(book.id); 
      DocumentSnapshot docSnapshot = await bookDocRef.get();
      String statusString = status.toString().split('.').last;
      if (docSnapshot.exists) {
        await bookDocRef.update({
          'reading_list': true,
          'reading_status': statusString,
        });
        print('Book updated in reading list with status: $statusString.');
      } else {
        await bookDocRef.set({
          'id': book.id,
          'reading_list': true,
          'reading_status': statusString,
        });
        print('Book added to reading list with status: $statusString.');
      }
    } catch (e) {
      print('Error updating reading list: $e');
      throw Exception('Failed to update reading list.');
    }
  }


  Future<void> removeBookFromReadingList(String bookId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently signed in.');
    try {
      DocumentReference bookDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('books')
          .doc(bookId);
      DocumentSnapshot docSnapshot = await bookDocRef.get();
      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;
        bool isFavorite = data['favorite'] ?? false;
        bool isReviewed = data['reviewed'] ?? false;
        if (!isFavorite && !isReviewed) {
          await bookDocRef.delete();
          print('Book removed entirely from user collection.');
        } else {
          await bookDocRef.update({'reading_list': false});
          print('Book removed from reading list, kept in collection.');
        }
      } else {
        throw Exception('Book not found in user\'s books collection.');
      }
    } catch (e) {
      throw Exception('Error removing book from reading list: $e');
    }
  }


  Future<void> changeReadingStatus(String bookId, ReadingStatus newStatus) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference bookDocRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('books')
            .doc(bookId);
        DocumentSnapshot docSnapshot = await bookDocRef.get();
        if (docSnapshot.exists) {
          await bookDocRef.update({
            'reading_status': newStatus.toString().split('.').last,
          });
          print('Reading status updated for book.');
        } else {
          print('Book not found in user\'s books collection.');
        }
      } catch (e) {
        print('Error changing reading status: $e');
        throw Exception('Failed to change reading status.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }


  Future<List<Map<String, dynamic>>> getReadingList() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        CollectionReference booksRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('books');
        QuerySnapshot querySnapshot = await booksRef.where('reading_list', isEqualTo: true).get();
        List<Map<String, dynamic>> readingList = querySnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'id': data['id'],
            'reading_status': data['reading_status'] ?? 'unknown',
          };
        }).toList();
        return readingList;
      } catch (e) {
        print('Error retrieving books from reading list: $e');
        throw Exception('Failed to retrieve books from reading list.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }


  Future<bool> isBookInFavorites(String bookId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference bookDocRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('books')
            .doc(bookId);
        DocumentSnapshot docSnapshot = await bookDocRef.get();
        if (docSnapshot.exists) {
          var data = docSnapshot.data() as Map<String, dynamic>;
          bool isFavorite = data['favorite'] == true;
          return isFavorite;
        } else {
          return false;
        }
      } catch (e) {
        print('Error checking favorite status: $e');
        return false;
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }


  Future<bool> isBookInReadingList(String bookId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference bookDocRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('books')
            .doc(bookId);
        DocumentSnapshot docSnapshot = await bookDocRef.get();
        if (docSnapshot.exists) {
          var data = docSnapshot.data() as Map<String, dynamic>;
          bool isInReadingList = data['reading_list'] == true;
          return isInReadingList;
        } else {
          return false;
        }
      } catch (e) {
        print('Error checking reading list status: $e');
        return false;
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<void> updateUserFavoriteGenres(List<String> genresToSet) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference userRef = _firestore.collection('users').doc(user.uid);
        await userRef.update({
          'favorite genres': genresToSet,
        });
        print('User genres updated successfully.');
      } catch (e) {
        print('Error updating genres: $e');
        throw Exception('Failed to update genres.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<List<String>> loadUserFavoriteGenres() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference userRef = _firestore.collection('users').doc(user.uid);
        DocumentSnapshot userDoc = await userRef.get();
        if (userDoc.exists) {
          List<dynamic> genresData = userDoc['favorite genres'] ?? [];
          List<String> genres = genresData.map((genre) => genre.toString()).toList();
          return genres;
        } else {
          return [];
        }
      } catch (e) {
        print('Error loading user genres: $e');
        throw Exception('Failed to load user genres.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<void> updateUserDislikedGenres(List<String> genresToSet) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference userRef = _firestore.collection('users').doc(user.uid);
        await userRef.update({
          'disliked genres': genresToSet,
        });
        print('User genres updated successfully.');
      } catch (e) {
        print('Error updating genres: $e');
        throw Exception('Failed to update genres.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<List<String>> loadUserDislikedGenres() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference userRef = _firestore.collection('users').doc(user.uid);
        DocumentSnapshot userDoc = await userRef.get();
        if (userDoc.exists) {
          List<dynamic> genresData = userDoc['disliked genres'] ?? [];
          List<String> genres = genresData.map((genre) => genre.toString()).toList();
          return genres;
        } else {
          return [];
        }
      } catch (e) {
        print('Error loading user genres: $e');
        throw Exception('Failed to load user genres.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<void> addBookToReviews(Book book, int rating, String reviewText) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference bookDocRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('books')
            .doc(book.id);
        DocumentSnapshot docSnapshot = await bookDocRef.get();
        if (docSnapshot.exists) {
          await bookDocRef.update({
            'reviewed': true,
            'rating': rating,
            'review': reviewText,
          });
          print('Book review added or updated successfully.');
        } else {
          print('Book not found in user\'s collection.');
        }
      } catch (e) {
        print('Error adding/updating review: $e');
        throw Exception('Failed to add/update book review.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<List<Map<String, dynamic>>> getReviews() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        CollectionReference booksRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('books');
        QuerySnapshot querySnapshot = await booksRef
            .where('reviewed', isEqualTo: true)
            .get();
        List<Map<String, dynamic>> reviewedBooks = querySnapshot.docs.map((doc) {
          var bookData = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id, 
            'rating': bookData['rating'],
            'review': bookData['review'],
          };
        }).toList();
        return reviewedBooks;
      } catch (e) {
        print('Error retrieving reviews: $e');
        throw Exception('Failed to retrieve reviews.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }


  Future<Map<String, dynamic>?> getBookReview(String bookId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference reviewsRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('books')
            .doc(bookId);
        DocumentSnapshot docSnapshot = await reviewsRef.get();
        if (docSnapshot.exists) {
          var data = docSnapshot.data() as Map<String, dynamic>;
          if (data['reviewed'] == true) {
            return {
              'rating': data['rating'],
              'review': data['review'],
            };
          }
        }
        return null;
      } catch (e) {
        print('Error retrieving book review: $e');
      }
    }
    return null;
  }

  User? get currentUser => _auth.currentUser;
}