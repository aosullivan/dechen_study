import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/web_navigation.dart';

class DechenHomeAction extends StatelessWidget {
  const DechenHomeAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home_outlined),
      color: const Color(0xFF2C2416),
      tooltip: 'Home',
      onPressed: () {
        if (kIsWeb) {
          leaveAppToDechenStudy();
          return;
        }
        replaceAppPath('/');
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}
