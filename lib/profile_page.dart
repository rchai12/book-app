import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'authentication.dart';
import 'message_history.dart';
import 'favorite_book_genres.dart';
import 'disliked_book_genres.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const ProfilePage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _nameController = TextEditingController();
  DateTime? _dob;
  bool _isEditingName = false;
  bool _isEditingDob = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      final userDoc = await widget.authService.getUserData();
      if (userDoc != null && userDoc.exists) {
        final userData = userDoc.data()!;
        _nameController.text = userData['name'];
        _dob = (userData['date_of_birth'] as Timestamp).toDate();
        setState(() {});
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    setState(() => _isLoading = true);
    try {
      await widget.authService.updateName(_nameController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
      setState(() => _isEditingName = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDob(DateTime newDob) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'date_of_birth': Timestamp.fromDate(newDob)});
      setState(() {
        _dob = newDob;
        _isEditingDob = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date of birth updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating DOB: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) await _updateDob(picked);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDob = _dob != null ? DateFormat.yMMMd().format(_dob!) : 'Not set';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: _nameController == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: [
                  const SizedBox(height: 12),
                  Icon(Icons.account_circle, size: 80, color: theme.primaryColor),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      widget.user.email ?? '',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _isEditingName
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _updateName,
                                    child: const Text('Save Name'),
                                  ),
                            TextButton(
                              onPressed: () => setState(() => _isEditingName = false),
                              child: const Text('Cancel'),
                            ),
                          ],
                        )
                      : ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Full Name'),
                          subtitle: Text(_nameController.text),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => setState(() => _isEditingName = true),
                          ),
                        ),

                  const Divider(height: 32),

                  _isEditingDob
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Date of Birth'),
                              subtitle: Text(formattedDob),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: _pickDob,
                              ),
                            ),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _pickDob,
                                    child: const Text('Update Date'),
                                  ),
                            TextButton(
                              onPressed: () => setState(() => _isEditingDob = false),
                              child: const Text('Cancel'),
                            ),
                          ],
                        )
                      : ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Date of Birth'),
                          subtitle: Text(formattedDob),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_calendar),
                            onPressed: () => setState(() => _isEditingDob = true),
                          ),
                        ),

                  const Divider(height: 32),

                  /// --- Navigation Buttons ---
                  _buildNavButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Message History',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessageHistoryPage(
                            user: widget.user,
                            authService: widget.authService,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildNavButton(
                    icon: Icons.favorite_border,
                    label: 'Favorite Book Genres',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FavoriteBookGenresPage(
                            user: widget.user,
                            authService: widget.authService,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildNavButton(
                    icon: Icons.block,
                    label: 'Disliked Book Genres',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DislikedBookGenresPage(
                            user: widget.user,
                            authService: widget.authService,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildNavButton(
                    icon: Icons.refresh,
                    label: 'Refresh Account',
                    onTap: () async {
                      await widget.authService.currentUser!.reload();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account Reloaded')),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}
