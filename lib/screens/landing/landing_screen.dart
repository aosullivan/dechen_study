import 'package:flutter/material.dart';
import 'text_options_screen.dart';

/// dechen.study-style landing: light yellow background, text cards with Details button.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color _backgroundYellow = Color(0xFFEADCC4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundYellow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: _BodhicaryavataraCard(
              onTap: () => _openTextOptions(context),
            ),
          ),
        ),
      ),
    );
  }

  void _openTextOptions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TextOptionsScreen(
          textId: 'bodhicaryavatara',
          title: 'Bodhicaryavatara',
        ),
      ),
    );
  }
}

class _BodhicaryavataraCard extends StatelessWidget {
  const _BodhicaryavataraCard({required this.onTap});

  final VoidCallback onTap;

  static const Color _cardBeige = Color(0xFFF8F7F3);
  static const Color _textDark = Color(0xFF2C2416);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBeige,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E4DC), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bodhicaryavatara',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontFamily: 'Crimson Text',
                      color: _textDark,
                      fontWeight: FontWeight.w600,
                    ) ??
                    const TextStyle(
                      fontFamily: 'Crimson Text',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'SANTIDEVA',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Crimson Text',
                      color: _textDark,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ) ??
                    const TextStyle(
                      fontFamily: 'Crimson Text',
                      fontSize: 16,
                      color: _textDark,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 24),
              _DetailsButton(onPressed: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

/// Black button with white "Details" text and concave left edge (dechen.study style).
class _DetailsButton extends StatelessWidget {
  const _DetailsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        height: 48,
        child: ClipPath(
          clipper: _ConcaveLeftButtonClipper(),
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: const Text(
              'Details',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Lora',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConcaveLeftButtonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 8.0;
    const indent = 12.0; // how far right the concave dip goes
    final path = Path();
    // Start at top-left (after small curve)
    path.moveTo(indent, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
    );
    path.lineTo(indent, size.height);
    // Concave curve on the left: bulge inward (to the right)
    path.quadraticBezierTo(
      indent + 16,
      size.height * 0.5,
      indent,
      0,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
