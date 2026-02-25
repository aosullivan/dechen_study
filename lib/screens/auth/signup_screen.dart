import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_form_layout.dart';
import '../../widgets/auth_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      showAuthError(context, 'Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showAuthError(context, 'Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      showAuthError(context, 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (response.user != null) {
        _showSuccess();
      }
    } catch (e) {
      showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Check Your Email'),
        content: const Text(
          'We\'ve sent you a confirmation email. Please click the link in the email to verify your account before signing in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to login
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AuthFormLayout(
        title: 'Create Account',
        subtitle: 'Begin your study journey',
        children: [
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: true,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
