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
        CollectionReference favoritesRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favorites');
        QuerySnapshot existingBooks = await favoritesRef
            .where('id', isEqualTo: book.id)
            .get();
        if (existingBooks.docs.isEmpty) {
          await favoritesRef.add(book.toMap());
          print('Book added to favorites.');
        } else {
          print('This book is already in the favorites.');
        }
      } catch (e) {
        print('Error adding book to favorites: $e');
        throw Exception('Failed to add book to favorites.');
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
      CollectionReference favoritesRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites');
      QuerySnapshot querySnapshot = await favoritesRef
          .where('id', isEqualTo: bookId)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
        print('Book removed from favorites.');
      } else {
        print('Book not found in favorites.');
      }
    } catch (e) {
      print('Error removing book from favorites: $e');
      throw Exception('Failed to remove book from favorites.');
    }
  }

  Future<List<Book>> getFavorites() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        CollectionReference favoritesRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favorites');
        QuerySnapshot querySnapshot = await favoritesRef.get();
        List<Book> favoriteBooks = querySnapshot.docs.map((doc) {
          var bookData = doc.data() as Map<String, dynamic>;
          return Book.fromMap(bookData);
        }).toList();
        return favoriteBooks;
      } catch (e) {
        print('Error retrieving favorites: $e');
        throw Exception('Failed to retrieve favorites.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<void> addBookToReadingList({
    required Book book,
    required ReadingStatus status,
  }) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        CollectionReference readingListRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('readingList');
        QuerySnapshot existingBooks = await readingListRef
            .where('id', isEqualTo: book.id)
            .get();
        if (existingBooks.docs.isEmpty) {
          var bookData = book.toMap();
          bookData['status'] = status.toString().split('.').last;
          await readingListRef.add(bookData);
          print('Book added to reading list.');
        } else {
          print('This book is already in the reading list.');
        }
      } catch (e) {
        print('Error adding book to reading list: $e');
        throw Exception('Failed to add book to reading list.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<void> removeBookFromReadingList(String bookId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently signed in.');
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('readingList') 
          .get();
      final doc = snapshot.docs.firstWhere(
        (doc) => doc.data()['id'] == bookId,
        orElse: () => throw Exception('Book not found in reading list.'),
      );
      await doc.reference.delete();
      print('Book removed from reading list.');
    } catch (e) {
      throw Exception('Error removing book from reading list: $e');
    }
  }

  Future<void> changeReadingStatus(String bookId, ReadingStatus newStatus) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        CollectionReference readingListRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('readingList');
        QuerySnapshot existingBooks = await readingListRef
            .where('id', isEqualTo: bookId)
            .get();
        if (existingBooks.docs.isNotEmpty) {
          var doc = existingBooks.docs.first;
          await doc.reference.update({
            'status': newStatus.toString().split('.').last,
          });
          print('Reading status updated for book.');
        } else {
          print('Book not found in reading list.');
        }
      } catch (e) {
        print('Error changing reading status: $e');
        throw Exception('Failed to change reading status.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<List<Book>> getBooksFromReadingList() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        CollectionReference readingListRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('readingList');
        QuerySnapshot querySnapshot = await readingListRef.get();
        List<Book> readingListBooks = querySnapshot.docs.map((doc) {
          var bookData = doc.data() as Map<String, dynamic>;
          return Book.fromMap(bookData);
        }).toList();
        return readingListBooks;
      } catch (e) {
        print('Error retrieving books from reading list: $e');
        throw Exception('Failed to retrieve books from reading list.');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  User? get currentUser => _auth.currentUser;
}