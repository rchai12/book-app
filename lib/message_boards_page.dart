import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'authentication.dart';
import 'message_board.dart';

class MessageBoardsPage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const MessageBoardsPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  _MessageBoardsPageState createState() => _MessageBoardsPageState();
}

class _MessageBoardsPageState extends State<MessageBoardsPage> {
  late Future<List<Map<String, dynamic>>> _messageBoards;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _messageBoards = widget.authService.getAllMessageBoards();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    try {
      DocumentSnapshot<Map<String, dynamic>>? userData =
          await widget.authService.getUserData();
      if (userData != null && userData.exists) {
        String role = userData.data()?['role'] ?? '';
        if (role == 'admin') {
          setState(() {
            _isAdmin = true;
          });
        }
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  void _showCreateMessageBoardDialog() {
    final titleController = TextEditingController();
    final imageUrlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Message Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: imageUrlController,
              decoration: InputDecoration(labelText: 'Image URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String title = titleController.text.trim();
              String imageUrl = imageUrlController.text.trim();
              String userId = widget.user.uid;
              if (title.isNotEmpty && imageUrl.isNotEmpty) {
                try {
                  await widget.authService.createMessageBoard(
                    title: title,
                    createdByUserId: userId,
                    imageUrl: imageUrl,
                  );
                  Navigator.of(context).pop();
                  setState(() {
                    _messageBoards =
                        widget.authService.getAllMessageBoards();
                  });
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating board: $e'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Message Boards')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _messageBoards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No message boards available.'));
          } else {
            List<Map<String, dynamic>> boards = snapshot.data!;
            boards.sort((a, b) => a['title'].toString().toLowerCase().compareTo(b['title'].toString().toLowerCase()));
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: boards.length,
                itemBuilder: (context, index) {
                  var board = boards[index];
                  String boardId = board['id'];
                  String title = board['title'];
                  String imageUrl = board['image'];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageBoardPage(
                            user: widget.user,
                            authService: widget.authService,
                            messageBoardId: boardId,
                            title: title,
                            imageUrl: imageUrl,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              color: Colors.black.withOpacity(0.5),
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _showCreateMessageBoardDialog,
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
