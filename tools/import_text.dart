import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// This script helps you import a structured text file into Supabase
// Format your text file like this:
//
// # Chapter 1: Introduction
// Section text here...
//
// ---
//
// Second section text here...
//
// # Chapter 2: The Path
// First section of chapter 2...

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final supabase = Supabase.instance.client;

  // Read the text file
  print('Enter the path to your text file:');
  final filePath = stdin.readLineSync();

  if (filePath == null || filePath.isEmpty) {
    print('No file path provided');
    return;
  }

  final file = File(filePath);
  if (!file.existsSync()) {
    print('File not found: $filePath');
    return;
  }

  final content = await file.readAsString();

  // Parse the content
  final chapters = parseTextFile(content);

  print('\nFound ${chapters.length} chapters');
  print('Ready to upload? (y/n)');
  final confirm = stdin.readLineSync();

  if (confirm?.toLowerCase() != 'y') {
    print('Upload cancelled');
    return;
  }

  // Upload to Supabase
  try {
    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];

      print('Uploading Chapter ${chapter['number']}: ${chapter['title']}');

      // Insert chapter
      final chapterResponse = await supabase
          .from('chapters')
          .insert({
            'chapter_number': chapter['number'],
            'title': chapter['title'],
          })
          .select()
          .single();

      final chapterId = chapterResponse['id'];

      // Insert sections
      final sections = chapter['sections'] as List<String>;
      for (var j = 0; j < sections.length; j++) {
        await supabase.from('sections').insert({
          'chapter_id': chapterId,
          'content': sections[j],
          'order_index': j,
        });
      }

      print('  ✓ Uploaded ${sections.length} sections');
    }

    print('\n✅ Successfully uploaded all content!');
  } catch (error) {
    print('\n❌ Error uploading: $error');
  }
}

List<Map<String, dynamic>> parseTextFile(String content) {
  final chapters = <Map<String, dynamic>>[];

  // Split by chapter headers (lines starting with #)
  final lines = content.split('\n');

  Map<String, dynamic>? currentChapter;
  List<String> currentSections = [];
  StringBuffer currentSection = StringBuffer();

  for (var line in lines) {
    if (line.trim().startsWith('#')) {
      // Save previous chapter
      if (currentChapter != null && currentSection.isNotEmpty) {
        currentSections.add(currentSection.toString().trim());
        currentChapter['sections'] = currentSections;
        chapters.add(currentChapter);
      }

      // Start new chapter
      final headerText = line.replaceFirst('#', '').trim();
      final parts = headerText.split(':');

      int chapterNumber = chapters.length + 1;
      String title = headerText;

      if (parts.length > 1) {
        // Try to extract number from "Chapter 1" format
        final numberMatch = RegExp(r'\d+').firstMatch(parts[0]);
        if (numberMatch != null) {
          chapterNumber = int.parse(numberMatch.group(0)!);
        }
        title = parts.sublist(1).join(':').trim();
      }

      currentChapter = {
        'number': chapterNumber,
        'title': title,
      };
      currentSections = [];
      currentSection = StringBuffer();
    } else if (line.trim() == '---') {
      // Section separator
      if (currentSection.isNotEmpty) {
        currentSections.add(currentSection.toString().trim());
        currentSection = StringBuffer();
      }
    } else {
      // Regular content line
      if (line.trim().isNotEmpty) {
        currentSection.writeln(line);
      }
    }
  }

  // Save last chapter
  if (currentChapter != null) {
    if (currentSection.isNotEmpty) {
      currentSections.add(currentSection.toString().trim());
    }
    currentChapter['sections'] = currentSections;
    chapters.add(currentChapter);
  }

  return chapters;
}
