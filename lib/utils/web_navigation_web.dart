// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

bool openGatewayToKnowledgePage() {
  final url = Uri.base.resolve('gateway-to-knowledge.html').toString();
  html.window.location.assign(url);
  return true;
}
