import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Shared layout for auth screens (login, sign up): scrollable centered form
/// with max width 400, consistent padding and column alignment.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.children,
  });

  /// Optional widget above the title (e.g. Supabase not configured banner).
  final Widget? leading;

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(height: 24),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 48),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows an error SnackBar with consistent styling for auth screens.
void showAuthError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.darkBrown,
    ),
  );
}
