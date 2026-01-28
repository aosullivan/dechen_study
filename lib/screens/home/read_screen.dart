import 'package:flutter/material.dart';
import '../../models/study_models.dart';
import '../../services/study_service.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  final _studyService = StudyService();
  bool _isLoading = true;
  List<Chapter> _chapters = [];
  int _selectedChapterIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoading = true);

    final chapters = await _studyService.getChapters();

    setState(() {
      _chapters = chapters;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B7355)),
      );
    }

    if (_chapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No study text available yet. Please upload a text first.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final currentChapter = _chapters[_selectedChapterIndex];

    return Column(
      children: [
        // Chapter selector
        Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFD4C4B0).withOpacity(0.3),
              ),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _chapters.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedChapterIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('Chapter ${_chapters[index].number}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedChapterIndex = index);
                    }
                  },
                  selectedColor: const Color(0xFF8B7355).withOpacity(0.3),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF8B7355)
                        : const Color(0xFFD4C4B0),
                  ),
                ),
              );
            },
          ),
        ),

        // Chapter content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chapter ${currentChapter.number}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                if (currentChapter.title.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    currentChapter.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF8B7355),
                        ),
                  ),
                ],
                const SizedBox(height: 32),
                
                // Sections
                ...currentChapter.sections.asMap().entries.map((entry) {
                  final section = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFD4C4B0),
                        ),
                      ),
                      child: Text(
                        section.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
