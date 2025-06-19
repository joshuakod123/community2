// lib/sub_screens/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/loading_widget.dart';
import '../localization/app_localizations.dart';
import 'package:experiment3/services/notification_display_service.dart';
import '../pages/main_page.dart';

// Define the app colors as constants
const Color kPaynesGrey = Color(0xFF536878);
const Color kPearl = Color(0xFFEAE0C8);

class EditProfilePage extends StatefulWidget {
  final String currentFirstName;
  final String currentLastName;
  final String currentEmail;
  final bool forcePasswordChange;

  const EditProfilePage({
    Key? key,
    required this.currentFirstName,
    required this.currentLastName,
    required this.currentEmail,
    this.forcePasswordChange = false,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _showPasswordFields = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.currentFirstName;
    _lastNameController.text = widget.currentLastName;
    _emailController.text = widget.currentEmail;
    _showPasswordFields = widget.forcePasswordChange;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Gets the user ID, prioritizing an active session, but falling back to local storage for temp users.
  Future<String?> _getUserId() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      return currentUser.id;
    }
    // Fallback for temporary password users
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id');
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('Could not identify user. Please log in again.');
      }

      // 1. Update user profile information (first/last name) in the 'users' table
      await _supabase.from('users').update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
      }).eq('id', userId);

      // 2. Handle email and password updates which require an active auth session
      final newPassword = _newPasswordController.text;
      if (widget.forcePasswordChange && newPassword.isNotEmpty) {
        // Special flow for temporary users setting their permanent password
        await _setupNewPasswordForTempUser(newPassword);

        // After setting password, clear the temp password from the database
        await _supabase.from('users').update({
          'temp_password': null,
          'password_reset_required': false,
        }).eq('id', userId);

        // Clean up local temp password data
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('temp_password_${widget.currentEmail}');
        await prefs.remove('temp_user_id_${widget.currentEmail}');
        final tempEmails = prefs.getStringList('temp_password_emails') ?? [];
        tempEmails.remove(widget.currentEmail);
        await prefs.setStringList('temp_password_emails', tempEmails);

      } else {
        // Flow for regularly logged-in users
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          // Update email if it has changed
          if (_emailController.text.trim() != widget.currentEmail) {
            await _supabase.auth.updateUser(
              UserAttributes(email: _emailController.text.trim()),
            );
          }
          // Update password if fields are shown and a new password is provided
          if (_showPasswordFields && newPassword.isNotEmpty) {
            await _supabase.auth.updateUser(
              UserAttributes(password: newPassword),
            );
          }
        }
      }

      if (mounted) {
        NotificationDisplayService.showPopupNotification(
          context,
          title: "Profile updated successfully",
          isSuccess: true,
          duration: const Duration(seconds: 2),
        );
        // If it was a forced password change, navigate to the main page
        if (widget.forcePasswordChange) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainPageUI()),
                (route) => false,
          );
        } else {
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationDisplayService.showPopupNotification(
          context,
          title: 'Error updating profile: ${e.toString()}',
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // This function establishes a proper auth record for a user who logged in with a temporary password.
  Future<void> _setupNewPasswordForTempUser(String newPassword) async {
    final email = _emailController.text.trim();
    try {
      // First, try to sign up the user. This creates their record in the 'auth.users' table.
      // It's safe to do because we already know their email is in our public.users table.
      await _supabase.auth.signUp(email: email, password: newPassword);
    } catch (e) {
      // If signUp fails (e.g., "User already registered"), it's okay.
      // We'll just proceed to sign them in, which will give us a valid session.
      print("Sign up attempt during password setup failed (this might be expected): $e");
    }

    // Now, sign in with the new credentials to establish a valid session
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: newPassword,
    );

    if (response.user == null) {
      throw Exception("Failed to establish a session with the new password.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocal = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: kPearl,
      appBar: AppBar(
        backgroundColor: kPaynesGrey,
        title: Text(
          appLocal.translate('edit_profile'),
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informational message for forced password change
              if (widget.forcePasswordChange)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "For your security, please set a new password.",
                          style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: appLocal.translate('first_name'),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.person_outline, color: kPaynesGrey),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: appLocal.translate('last_name'),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.person_outline, color: kPaynesGrey),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                readOnly: widget.forcePasswordChange, // Don't allow email change for temp users here
                decoration: InputDecoration(
                  labelText: appLocal.translate('email'),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.email_outlined, color: kPaynesGrey),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Change Password Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appLocal.translate('change_password'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPaynesGrey,
                    ),
                  ),
                  Switch(
                    value: _showPasswordFields,
                    onChanged: (value) {
                      // Prevent turning off if it's a forced change
                      if (widget.forcePasswordChange && !value) {
                        NotificationDisplayService.showPopupNotification(context,
                          title: "You must set a new password.",
                          isError: true,
                        );
                        return;
                      }
                      setState(() {
                        _showPasswordFields = value;
                        if (!value) {
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        }
                      });
                    },
                    activeColor: kPaynesGrey,
                  ),
                ],
              ),

              if (_showPasswordFields) ...[
                const SizedBox(height: 16),

                // New Password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: appLocal.translate('new_password'),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: kPaynesGrey),
                  ),
                  validator: (value) {
                    if (_showPasswordFields && (value == null || value.isEmpty)) {
                      return 'Please enter a new password';
                    }
                    if (_showPasswordFields && value!.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: appLocal.translate('confirm_password'),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: kPaynesGrey),
                  ),
                  validator: (value) {
                    if (_showPasswordFields && value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPaynesGrey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    appLocal.translate('save_changes'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}