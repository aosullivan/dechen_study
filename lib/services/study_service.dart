import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/study_models.dart';
import '../utils/constants.dart';

class StudyService {
  StudyService._();
  static final StudyService _instance = StudyService._();
  static StudyService get instance => _instance;

  ({DateTime startOfDayUtc, DateTime endOfDayUtc}) _utcDayWindow(
      DateTime nowUtc) {
    final startOfDayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final endOfDayUtc = startOfDayUtc.add(const Duration(days: 1));
    return (startOfDayUtc: startOfDayUtc, endOfDayUtc: endOfDayUtc);
  }

  Future<DailySection?> _loadDailySectionForUtcDay(
    String userId, {
    required DateTime startOfDayUtc,
    required DateTime endOfDayUtc,
  }) async {
    final response = await supabase
        .from('daily_sections')
        .select('*')
        .eq('user_id', userId)
        .gte('date', startOfDayUtc.toIso8601String())
        .lt('date', endOfDayUtc.toIso8601String())
        .order('date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return DailySection.fromJson(response);
  }

  Future<T> _guard<T>(
      String operation, T fallback, Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('Error $operation: $e');
      return fallback;
    }
  }

  // Get the study text (we'll have just one for now)
  Future<StudyText?> getStudyText() async {
    return _guard<StudyText?>('fetching study text', null, () async {
      final response = await supabase
          .from('study_texts')
          .select('*, chapters(*, sections(*))')
          .single();

      return StudyText.fromJson(response);
    });
  }

  // Get all sections flattened
  Future<List<Section>> getAllSections() async {
    return _guard<List<Section>>('fetching sections', [], () async {
      final response = await supabase
          .from('sections')
          .select('*')
          .order('chapter_number')
          .order('id');

      return (response as List)
          .map((s) => Section.fromJson(s as Map<String, dynamic>))
          .toList();
    });
  }

  // Get a random section
  Future<Section?> getRandomSection() async {
    return _guard<Section?>('getting random section', null, () async {
      final sections = await getAllSections();
      if (sections.isEmpty) return null;

      final random = Random();
      return sections[random.nextInt(sections.length)];
    });
  }

  // Get today's daily section
  Future<DailySection?> getTodaysDailySection(String userId) async {
    return _guard<DailySection?>('fetching daily section', null, () async {
      final nowUtc = DateTime.now().toUtc();
      final dayWindow = _utcDayWindow(nowUtc);
      final response = await _loadDailySectionForUtcDay(
        userId,
        startOfDayUtc: dayWindow.startOfDayUtc,
        endOfDayUtc: dayWindow.endOfDayUtc,
      );

      if (response == null) {
        // Create new daily section for today
        return await createDailySection(userId);
      }

      return response;
    });
  }

  // Create a new daily section
  Future<DailySection?> createDailySection(String userId) async {
    return _guard<DailySection?>('creating daily section', null, () async {
      final nowUtc = DateTime.now().toUtc();
      final dayWindow = _utcDayWindow(nowUtc);
      final existing = await _loadDailySectionForUtcDay(
        userId,
        startOfDayUtc: dayWindow.startOfDayUtc,
        endOfDayUtc: dayWindow.endOfDayUtc,
      );
      if (existing != null) return existing;

      // Get the last completed section to pick the next one
      final lastDaily = await supabase
          .from('daily_sections')
          .select('section_id')
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      final sections = await getAllSections();
      if (sections.isEmpty) return null;

      Section nextSection;
      if (lastDaily == null) {
        // First time - start with first section
        nextSection = sections.first;
      } else {
        // Find next section
        final lastSectionId = lastDaily['section_id'];
        final currentIndex = sections.indexWhere((s) => s.id == lastSectionId);
        if (currentIndex == -1 || currentIndex == sections.length - 1) {
          nextSection = sections.first; // Loop back to start
        } else {
          nextSection = sections[currentIndex + 1];
        }
      }

      final dailySectionsTable = supabase.from('daily_sections');
      try {
        final inserted = await dailySectionsTable
            .insert({
              'user_id': userId,
              'section_id': nextSection.id,
              'date': nowUtc.toIso8601String(),
              'completed': false,
            })
            .select()
            .single();
        return DailySection.fromJson(inserted);
      } on PostgrestException catch (error) {
        // Another request may have inserted today's row first.
        if (error.code == '23505') {
          return _loadDailySectionForUtcDay(
            userId,
            startOfDayUtc: dayWindow.startOfDayUtc,
            endOfDayUtc: dayWindow.endOfDayUtc,
          );
        }
        rethrow;
      }
    });
  }

  // Mark daily section as complete
  Future<bool> markDailySectionComplete(String dailySectionId) async {
    return _guard<bool>('marking section complete', false, () async {
      await supabase
          .from('daily_sections')
          .update({'completed': true}).eq('id', dailySectionId);
      return true;
    });
  }

  // Get section by ID
  Future<Section?> getSection(String sectionId) async {
    return _guard<Section?>('fetching section', null, () async {
      final response = await supabase
          .from('sections')
          .select('*')
          .eq('id', sectionId)
          .single();

      return Section.fromJson(response);
    });
  }

  // Get all chapters
  Future<List<Chapter>> getChapters() async {
    return _guard<List<Chapter>>('fetching chapters', [], () async {
      final response = await supabase
          .from('chapters')
          .select('*, sections(*)')
          .order('number');

      return (response as List)
          .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
          .toList();
    });
  }
}
