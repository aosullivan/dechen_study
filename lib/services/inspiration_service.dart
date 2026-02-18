import 'dart:math';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'bcv_verse_service.dart';
import 'verse_hierarchy_service.dart';

/// One feeling category for the Inspiration picker.
class FeelingCategory {
  const FeelingCategory({
    required this.id,
    required this.label,
    required this.hint,
  });
  final String id;
  final String label;
  final String hint;
}

/// A section with verse refs for a feeling (used to pick a random verse).
class InspirationSection {
  const InspirationSection({
    required this.path,
    required this.title,
    required this.verseRefs,
  });
  final String path;
  final String title;
  final List<String> verseRefs;
}

/// Result of picking one random verse for a feeling.
class InspirationRandomVerse {
  const InspirationRandomVerse({
    required this.verseRef,
    required this.verseText,
    required this.sectionTitle,
    required this.sectionPath,
  });
  final String verseRef;
  final String verseText;
  final String sectionTitle;
  final String sectionPath;
}

/// Loads full-text feeling→sections mapping and provides random verse by feeling.
class InspirationService {
  InspirationService._();
  static final InspirationService _instance = InspirationService._();
  static InspirationService get instance => _instance;

  static const String _assetPath = 'texts/full_text_feeling_advice_mapping.json';

  List<FeelingCategory>? _categories;
  Map<String, List<Map<String, dynamic>>>? _feelingToSectionsRaw;
  final _random = Random();

  Future<void> preload() => _ensureLoaded();

  Future<void> _ensureLoaded() async {
    if (_categories != null) return;
    final content = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(content) as Map<String, dynamic>;
    final categoriesList = data['feelingCategories'] as List<dynamic>? ?? [];
    _categories = categoriesList
        .map((c) {
          final map = c as Map<String, dynamic>;
          return FeelingCategory(
            id: map['id'] as String? ?? '',
            label: map['label'] as String? ?? '',
            hint: map['hint'] as String? ?? '',
          );
        })
        .where((c) => c.id.isNotEmpty)
        .toList();
    final toSections = data['feelingToSections'] as Map<String, dynamic>? ?? {};
    _feelingToSectionsRaw = <String, List<Map<String, dynamic>>>{};
    for (final e in toSections.entries) {
      final list = e.value as List<dynamic>? ?? [];
      _feelingToSectionsRaw![e.key.toString()] = list
          .map((s) => (s as Map<String, dynamic>))
          .where((s) => s['path'] != null && s['title'] != null)
          .toList();
    }
  }

  /// All feeling categories for the picker.
  Future<List<FeelingCategory>> getFeelingCategories() async {
    await _ensureLoaded();
    return List.from(_categories!);
  }

  /// Sections for [feelingId], enriched with verse refs from the hierarchy.
  Future<List<InspirationSection>> getSectionsForFeeling(String feelingId) async {
    await _ensureLoaded();
    await VerseHierarchyService.instance.preload();
    final raw = _feelingToSectionsRaw?[feelingId];
    if (raw == null || raw.isEmpty) return [];
    final result = <InspirationSection>[];
    for (final s in raw) {
      final path = s['path'] as String? ?? '';
      final title = s['title'] as String? ?? '';
      final refs = VerseHierarchyService.instance.getVerseRefsForSectionSync(path);
      if (refs.isEmpty) continue;
      final sorted = refs.toList()
        ..sort(VerseHierarchyService.compareVerseRefs);
      result.add(InspirationSection(
        path: path,
        title: title,
        verseRefs: sorted,
      ));
    }
    return result;
  }

  /// One random verse for [feelingId]. Returns null if no verses available.
  Future<InspirationRandomVerse?> getRandomVerseForFeeling(String feelingId) async {
    final sections = await getSectionsForFeeling(feelingId);
    if (sections.isEmpty) return null;
    final pairs = <({String ref, String title, String path})>[];
    for (final sec in sections) {
      for (final ref in sec.verseRefs) {
        pairs.add((ref: ref, title: sec.title, path: sec.path));
      }
    }
    if (pairs.isEmpty) return null;
    final p = pairs[_random.nextInt(pairs.length)];
    await BcvVerseService.instance.getChapters();
    final idx = BcvVerseService.instance.getIndexForRefWithFallback(p.ref);
    if (idx == null) return null;
    final text = BcvVerseService.instance.getVerseAt(idx) ?? '';
    return InspirationRandomVerse(
      verseRef: p.ref,
      verseText: text,
      sectionTitle: p.title,
      sectionPath: p.path,
    );
  }
}
