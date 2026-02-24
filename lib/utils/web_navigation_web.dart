// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

bool openGatewayToKnowledgePage() {
  final url = Uri.base.resolve('gateway-to-knowledge.html').toString();
  html.window.location.assign(url);
  return true;
}

bool openGatewayChapterPage(int chapterNumber) {
  if (chapterNumber <= 0) return false;
  final url = Uri.base
      .resolve('gateway-to-knowledge.html?chapter=$chapterNumber')
      .toString();
  html.window.location.assign(url);
  return true;
}

bool openExternalUrl(String url) {
  final parsed = Uri.tryParse(url);
  if (parsed == null || !parsed.hasScheme || !parsed.hasAuthority) {
    return false;
  }
  html.window.open(parsed.toString(), '_blank');
  return true;
}

bool isAppDechenStudyHost() {
  final host = Uri.base.host.toLowerCase();
  return host == 'app.dechen.study';
}

void leaveAppToDechenStudy() {
  html.window.location.assign('https://dechen.study');
}

String currentAppPath() {
  final path = Uri.base.path;
  return _normalizePath(path);
}

void pushAppPath(String path) {
  _setAppPath(path, replace: false);
}

void replaceAppPath(String path) {
  _setAppPath(path, replace: true);
}

void _setAppPath(String path, {required bool replace}) {
  final normalized = _normalizePath(path);
  if (normalized == currentAppPath()) return;
  if (replace) {
    html.window.history.replaceState(null, '', normalized);
    return;
  }
  html.window.history.pushState(null, '', normalized);
}

String _normalizePath(String rawPath) {
  if (rawPath.isEmpty) return '/';

  var normalized = rawPath;
  if (!normalized.startsWith('/')) {
    normalized = '/$normalized';
  }

  if (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }

  return normalized;
}
