// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

const String _stateCanGoBackKey = 'dechenCanGoBack';
const String _stateCurrentPathKey = 'dechenCurrentPath';
const String _stateFromPathKey = 'dechenFromPath';

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

bool hasBrowserBackTarget() {
  if (_hasInAppBackState()) return true;
  return _hasDechenStudyReferrer();
}

void navigateBrowserBack() {
  html.window.history.back();
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
  final currentPath = currentAppPath();
  if (normalized == currentPath) return;
  final state = jsonEncode(<String, Object?>{
    _stateCanGoBackKey: !replace,
    _stateCurrentPathKey: normalized,
    _stateFromPathKey: currentPath,
  });
  if (replace) {
    html.window.history.replaceState(state, '', normalized);
    return;
  }
  html.window.history.pushState(state, '', normalized);
}

bool _hasInAppBackState() {
  final state = html.window.history.state;
  return _readBoolState(state, _stateCanGoBackKey);
}

bool _hasDechenStudyReferrer() {
  final rawReferrer = html.document.referrer.trim();
  if (rawReferrer.isEmpty) return false;
  final referrer = Uri.tryParse(rawReferrer);
  if (referrer == null) return false;
  final host = referrer.host.toLowerCase();
  return host == 'dechen.study' || host.endsWith('.dechen.study');
}

bool _readBoolState(dynamic state, String key) {
  if (state == null) return false;
  if (state is String) {
    try {
      final decoded = jsonDecode(state);
      if (decoded is Map) {
        return decoded[key] == true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }
  if (state is Map) {
    return state[key] == true;
  }
  return false;
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
