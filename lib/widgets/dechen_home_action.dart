import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/mobile/mobile_home_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../utils/web_navigation.dart';

class DechenHomeAction extends StatelessWidget {
  const DechenHomeAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.home_outlined),
          color: const Color(0xFF2C2416),
          tooltip: 'Home',
          onPressed: () {
            if (kIsWeb) {
              leaveAppToDechenStudy();
              return;
            }
            replaceAppPath('/');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => const MobileHomeScreen(),
              ),
              (_) => false,
            );
          },
        ),
        if (!kIsWeb)
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF2C2416)),
            tooltip: 'Menu',
            onSelected: (action) {
              if (action == _MenuAction.settings) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<_MenuAction>(
                value: _MenuAction.settings,
                child: Text('Settings'),
              ),
            ],
          ),
      ],
    );
  }
}

enum _MenuAction { settings }
