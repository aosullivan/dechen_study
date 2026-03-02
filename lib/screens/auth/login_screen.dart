import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/web_navigation.dart';
import '../../widgets/auth_form_layout.dart';
import '../../widgets/auth_text_field.dart';
import '../landing/gateway_landing_screen.dart';
import '../landing/landing_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showAuthError(context, 'Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (response.user != null) {
        if (isAppDechenStudyHost()) {
          replaceAppPath('/gateway-to-knowledge');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GatewayLandingScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LandingScreen()),
          );
        }
      }
    } catch (e) {
      showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool configured = isSupabaseConfigured;
    return Scaffold(
      body: AuthFormLayout(
        leading: configured
            ? null
            : Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(height: 8),
                    Text(
                      'Supabase not configured',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Missing SUPABASE_URL / SUPABASE_ANON_KEY in .env',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
        title: 'Welcome',
        subtitle: 'Sign in to continue your study',
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_isLoading || !configured) ? null : _signIn,
            child: const Text('Sign In'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: !configured
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SignUpScreen(),
                      ),
                    );
                  },
            child: const Text('Don\'t have an account? Sign up'),
          ),
        ],
      ),
    );
  }
}
