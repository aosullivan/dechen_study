import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/study_text_config.dart';
import '../../services/usage_metrics_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/web_navigation.dart';
import 'gateway_landing_screen.dart';
import 'text_options_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const Color _backgroundYellow = AppColors.landingBackground;
  bool _redirectingToGateway = false;

  @override
  void initState() {
    super.initState();
    if (isAppDechenStudyHost()) {
      _redirectingToGateway = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        replaceAppPath('/gateway-to-knowledge');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const GatewayLandingScreen(),
          ),
        );
      });
    }
    // Do not preload BCV here. Gateway and Bodhicaryavatara are separate in prod;
    // we only load BCV when the user taps Bodhicaryavatara (see TextOptionsScreen).
  }

  @override
  Widget build(BuildContext context) {
    if (_redirectingToGateway) {
      return const Scaffold(
        backgroundColor: _backgroundYellow,
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _backgroundYellow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TextLandingCard(
                  title: 'Gateway to Knowledge',
                  author: 'JAMGON JU MIPHAM',
                  onTap: () => _openGatewayToKnowledge(context),
                ),
                ...getStudyTextsWithFullSupport().map(
                  (config) => [
                    const SizedBox(height: 20),
                    _TextLandingCard(
                      title: config.title,
                      author: config.author,
                      onTap: () => _openTextOptions(context, config),
                    ),
                  ],
                ).expand((e) => e),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTextOptions(BuildContext context, StudyTextConfig config) {
    _openText(
      context,
      textId: config.textId,
      path: config.path,
      screen: TextOptionsScreen(
        textId: config.textId,
        title: config.title,
      ),
    );
  }

  void _openGatewayToKnowledge(BuildContext context) {
    _openText(
      context,
      textId: 'gateway_to_knowledge',
      path: '/gateway-to-knowledge',
      screen: const GatewayLandingScreen(),
    );
  }

  void _openText(
    BuildContext context, {
    required String textId,
    required String path,
    required Widget screen,
  }) {
    pushAppPath(path);
    unawaited(UsageMetricsService.instance.trackEvent(
      eventName: 'text_opened',
      textId: textId,
      mode: 'text_options',
    ));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}

class _TextLandingCard extends StatelessWidget {
  const _TextLandingCard({
    required this.title,
    required this.author,
    required this.onTap,
  });

  final String title;
  final String author;
  final VoidCallback onTap;

  static const Color _cardBeige = AppColors.cardBeige;
  static const Color _textDark = AppColors.textDark;

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
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
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
                author,
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
    const indent = 12.0;
    final path = Path();
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
