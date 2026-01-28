import 'dart:math';
import '../utils/constants.dart';
import '../models/study_models.dart';

class StudyService {
  // Get the study text (we'll have just one for now)
  Future<StudyText?> getStudyText() async {
    try {
      final response = await supabase
          .from('study_texts')
          .select('*, chapters(*, sections(*))')
          .single();

      return StudyText.fromJson(response);
    } catch (e) {
      print('Error fetching study text: $e');
      return null;
    }
  }

  // Get all sections flattened
  Future<List<Section>> getAllSections() async {
    try {
      final response = await supabase
          .from('sections')
          .select('*')
          .order('chapter_number')
          .order('id');

      return (response as List).map((s) => Section.fromJson(s)).toList();
    } catch (e) {
      print('Error fetching sections: $e');
      return [];
    }
  }

  // Get a random section
  Future<Section?> getRandomSection() async {
    try {
      final sections = await getAllSections();
      if (sections.isEmpty) return null;
      
      final random = Random();
      return sections[random.nextInt(sections.length)];
    } catch (e) {
      print('Error getting random section: $e');
      return null;
    }
  }

  // Get today's daily section
  Future<DailySection?> getTodaysDailySection(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await supabase
          .from('daily_sections')
          .select('*')
          .eq('user_id', userId)
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String())
          .maybeSingle();

      if (response == null) {
        // Create new daily section for today
        return await createDailySection(userId);
      }

      return DailySection.fromJson(response);
    } catch (e) {
      print('Error fetching daily section: $e');
      return null;
    }
  }

  // Create a new daily section
  Future<DailySection?> createDailySection(String userId) async {
    try {
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

      final response = await supabase
          .from('daily_sections')
          .insert({
            'user_id': userId,
            'section_id': nextSection.id,
            'date': DateTime.now().toIso8601String(),
            'completed': false,
          })
          .select()
          .single();

      return DailySection.fromJson(response);
    } catch (e) {
      print('Error creating daily section: $e');
      return null;
    }
  }

  // Mark daily section as complete
  Future<bool> markDailySectionComplete(String dailySectionId) async {
    try {
      await supabase
          .from('daily_sections')
          .update({'completed': true})
          .eq('id', dailySectionId);
      return true;
    } catch (e) {
      print('Error marking section complete: $e');
      return false;
    }
  }

  // Get section by ID
  Future<Section?> getSection(String sectionId) async {
    try {
      final response = await supabase
          .from('sections')
          .select('*')
          .eq('id', sectionId)
          .single();

      return Section.fromJson(response);
    } catch (e) {
      print('Error fetching section: $e');
      return null;
    }
  }

  // Get all chapters
  Future<List<Chapter>> getChapters() async {
    try {
      final response = await supabase
          .from('chapters')
          .select('*, sections(*)')
          .order('number');

      return (response as List).map((c) => Chapter.fromJson(c)).toList();
    } catch (e) {
      print('Error fetching chapters: $e');
      return [];
    }
  }
}
