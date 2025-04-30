import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authentication.dart';
import 'login_page.dart';

class AccountPage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const AccountPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _newEmailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    setState(() => _isLoading = true);
    try {
      User? updatedUser = await widget.authService.updateEmail(
        email: widget.user.email!,
        currentPassword: _passwordController.text.trim(),
        newEmail: _newEmailController.text.trim(),
      );

      if (updatedUser != null) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email Updated'),
            content: const Text('You will now be logged out.'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await widget.authService.logoutUser();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _newEmailController.clear();
        _passwordController.clear();
        _isEditingEmail = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    setState(() => _isLoading = true);
    try {
      await widget.authService.updatePassword(
        email: widget.user.email!,
        currentPassword: _passwordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      setState(() => _isEditingPassword = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _newPasswordController.clear();
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Account Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Icon(Icons.lock_person_rounded, size: 80, color: theme.primaryColor),
            const SizedBox(height: 12),
            Center(
              child: Text(
                widget.user.email ?? '',
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 32),

            /// --- Email ---
            _isEditingEmail
                ? _buildEditableSection(
                    title: 'Email',
                    children: [
                      _buildTextField(
                        controller: _newEmailController,
                        label: 'New Email',
                        icon: Icons.email,
                      ),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        obscureText: true,
                        showText: _showCurrentPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _showCurrentPassword = !_showCurrentPassword;
                          });
                        },
                      ),
                      _buildActionButtons(
                        onSave: _updateEmail,
                        onCancel: () => setState(() => _isEditingEmail = false),
                      ),
                    ],
                  )
                : _buildStaticTile(
                    title: 'Email',
                    value: widget.user.email ?? '',
                    icon: Icons.email_outlined,
                    onEdit: () => setState(() {
                      _isEditingEmail = true;
                      _newEmailController.clear();
                      _passwordController.clear();
                    }),
                  ),

            const Divider(height: 32),

            /// --- Password ---
            _isEditingPassword
                ? _buildEditableSection(
                    title: 'Password',
                    children: [
                      _buildTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        showText: _showNewPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _showNewPassword = !_showNewPassword;
                          });
                        },
                      ),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Current Password',
                        icon: Icons.lock,
                        obscureText: true,
                        showText: _showCurrentPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _showCurrentPassword = !_showCurrentPassword;
                          });
                        },
                      ),
                      _buildActionButtons(
                        onSave: _updatePassword,
                        onCancel: () => setState(() {
                          _isEditingPassword = false;
                          _newPasswordController.clear();
                          _passwordController.clear();
                        }),
                      ),
                    ],
                  )
                : _buildStaticTile(
                    title: 'Password',
                    value: '********',
                    icon: Icons.lock_outline,
                    onEdit: () => setState(() => _isEditingPassword = true),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value),
      leading: Icon(icon),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: onEdit,
      ),
    );
  }

  Widget _buildEditableSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool obscureText = false,
  VoidCallback? onToggleVisibility,
  bool showText = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: controller,
      obscureText: obscureText && !showText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: obscureText
            ? IconButton(
                icon: Icon(
                  showText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
  );
}


  Widget _buildActionButtons({
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Column(
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: onSave,
                child: const Text('Save Changes'),
              ),
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
