import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/study_destination_catalog.dart';
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
  final List<StudyDestination> _destinations = getStudyDestinations();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurfaceColors.landingBackground(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _destinations
                  .asMap()
                  .entries
                  .map((entry) {
                    final destination = entry.value;
                    return [
                      if (entry.key > 0) const SizedBox(height: 20),
                      _TextLandingCard(
                        title: destination.title,
                        author: destination.author,
                        onTap: () => _openDestination(
                          context,
                          destination: destination,
                        ),
                      ),
                    ];
                  })
                  .expand((items) => items)
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _openDestination(
    BuildContext context, {
    required StudyDestination destination,
  }) {
    pushAppPath(destination.path);
    unawaited(UsageMetricsService.instance.trackEvent(
      eventName: 'text_opened',
      textId: destination.id,
      mode: 'text_options',
    ));
    final screen = destination.isGateway
        ? const GatewayLandingScreen()
        : TextOptionsScreen(
            textId: destination.textId!,
            title: destination.title,
          );
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

  @override
  Widget build(BuildContext context) {
    final cardColor = AppSurfaceColors.cardBackground(context);
    final textColor = AppSurfaceColors.textDark(context);
    final borderColor = AppSurfaceColors.borderLight(context);
    return Material(
      color: cardColor,
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
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontFamily: 'Crimson Text',
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ) ??
                    TextStyle(
                      fontFamily: 'Crimson Text',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                author,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'Crimson Text',
                          color: textColor,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ) ??
                    TextStyle(
                      fontFamily: 'Crimson Text',
                      fontSize: 16,
                      color: textColor,
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
                fontSize: 18,
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
