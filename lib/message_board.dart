import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'authentication.dart';
import 'message.dart';

class MessageBoardPage extends StatefulWidget {
  final User user;
  final AuthService authService;
  final String messageBoardId;
  final String title;
  final String imageUrl;

  const MessageBoardPage({
    super.key,
    required this.user,
    required this.authService,
    required this.messageBoardId,
    required this.title,
    required this.imageUrl,
  });

  @override
  State<MessageBoardPage> createState() => _MessageBoardPageState();
}

class _MessageBoardPageState extends State<MessageBoardPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    try {
      final userDoc = await widget.authService.getUserData();
      final role = userDoc?.data()?['role'] ?? '';
      setState(() {
        _isAdmin = role == 'admin';
      });
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.authService.deleteMessage(
          messageBoardId: widget.messageBoardId,
          messageId: messageId,
          userId: widget.user.uid,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await widget.authService.addMessageToCollection(
        userId: widget.user.uid,
        sender: widget.user.displayName ?? 'Unknown User',
        text: text,
        messageBoardId: widget.messageBoardId,
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Dark overlay
          Container(
            color: Colors.black.withOpacity(0.6),
          ),

          // Foreground content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('messageboard')
                        .doc(widget.messageBoardId)
                        .collection('messages')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No messages yet.', style: TextStyle(color: Colors.white70)));
                      }

                      final messages = snapshot.data!.docs.map((doc) => Message.fromDoc(doc)).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isOwn = message.userId == widget.user.uid;
                          final canDelete = _isAdmin || isOwn;

                          final messageCard = Card(
                            color: Colors.white.withOpacity(0.9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(message.sender, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(message.text, style: theme.textTheme.bodyMedium),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat.yMMMd().add_jm().format(message.timestamp.toDate()),
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );

                          return canDelete
                              ? Dismissible(
                                  key: Key(message.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  confirmDismiss: (_) async {
                                    await _deleteMessage(message.id);
                                    return false;
                                  },
                                  child: messageCard,
                                )
                              : messageCard;
                        },
                      );
                    },
                  ),
                ),

                /// Send Message Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, -1),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            fillColor: Colors.grey[100],
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: theme.primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
