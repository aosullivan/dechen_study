import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'verse_hierarchy_service.dart';

/// A section with its emotion mapping and verse references.
class InspirationSection {
  const InspirationSection({
    required this.path,
    required this.title,
    required this.emotion,
    required this.verseRefs,
  });
  final String path;
  final String title;
  final String emotion;
  final List<String> verseRefs;
}

/// Loads section-to-emotion mappings and provides filtered sections by emotion.
class InspirationService {
  InspirationService._();
  static final InspirationService _instance = InspirationService._();
  static InspirationService get instance => _instance;

  static const String _assetPath = 'texts/section_emotion_mappings.json';

  static const List<String> negativeEmotions = [
    'Worry / Anxiety',
    'Stress',
    'Sadness',
    'Anger / Frustration / Irritation',
    'Tiredness / Fatigue',
    'Disgust / Annoyance / Contempt',
    'Boredom',
    'Loneliness',
    'Fear / Apprehension',
    'Guilt / Regret',
    'Embarrassment / Shame',
    'Hopelessness / Discouragement',
    'Overwhelmed',
  ];

  /// Short display labels for the emotion picker UI.
  static const Map<String, String> emotionLabels = {
    'Worry / Anxiety': 'Worried',
    'Stress': 'Stressed',
    'Sadness': 'Sad',
    'Anger / Frustration / Irritation': 'Angry',
    'Tiredness / Fatigue': 'Tired',
    'Disgust / Annoyance / Contempt': 'Annoyed',
    'Boredom': 'Bored',
    'Loneliness': 'Lonely',
    'Fear / Apprehension': 'Fearful',
    'Guilt / Regret': 'Guilty',
    'Embarrassment / Shame': 'Ashamed',
    'Hopelessness / Discouragement': 'Hopeless',
    'Overwhelmed': 'Overwhelmed',
  };

  Map<String, List<_RawSection>>? _rawByEmotion;

  Future<void> preload() => _ensureLoaded();

  Future<void> _ensureLoaded() async {
    if (_rawByEmotion != null) return;
    final content = await rootBundle.loadString(_assetPath);
    await VerseHierarchyService.instance.preload();
    _rawByEmotion = await compute(_parseRaw, content);
  }

  /// Parse the JSON and collect leaf sections with verse refs, grouped by emotion.
  /// Runs in a background isolate — but verse ref lookup needs the main isolate,
  /// so we do a two-pass approach: parse in isolate, then enrich on main thread.
  static Map<String, List<_RawSection>> _parseRaw(String content) {
    final data = jsonDecode(content) as Map<String, dynamic>;
    final sections = data['sections'] as List<dynamic>? ?? [];
    final byEmotion = <String, List<_RawSection>>{};

    void visit(Map<String, dynamic> node) {
      final children = node['children'] as List<dynamic>?;
      final hasChildren = children != null && children.isNotEmpty;
      if (hasChildren) {
        for (final c in children) {
          if (c is Map<String, dynamic>) visit(c);
        }
      } else {
        // Leaf node
        final emotion = node['emotion'] as String? ?? '';
        final path = node['path'] as String? ?? '';
        final title = node['title'] as String? ?? '';
        if (emotion.isNotEmpty && path.isNotEmpty) {
          (byEmotion[emotion] ??= []).add(_RawSection(path: path, title: title));
        }
      }
    }

    for (final s in sections) {
      if (s is Map<String, dynamic>) visit(s);
    }
    return byEmotion;
  }

  /// Enriches raw sections with verse refs from VerseHierarchyService.
  /// Must be called on the main isolate after _ensureLoaded.
  List<InspirationSection> _enrichSections(List<_RawSection> raw) {
    final hierarchy = VerseHierarchyService.instance;
    final result = <InspirationSection>[];
    for (final s in raw) {
      final refs = hierarchy.getVerseRefsForSectionSync(s.path);
      if (refs.isEmpty) continue;
      final sorted = refs.toList()
        ..sort(VerseHierarchyService.compareVerseRefs);
      result.add(InspirationSection(
        path: s.path,
        title: s.title,
        emotion: '',
        verseRefs: sorted,
      ));
    }
    return result;
  }

  /// Returns sections for the given emotion, with verse refs populated.
  Future<List<InspirationSection>> getSectionsForEmotion(String emotion) async {
    await _ensureLoaded();
    final raw = _rawByEmotion?[emotion];
    if (raw == null || raw.isEmpty) return [];
    return _enrichSections(raw);
  }
}

class _RawSection {
  const _RawSection({required this.path, required this.title});
  final String path;
  final String title;
}
