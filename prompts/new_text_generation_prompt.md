# New Text Generation Prompt


Goal:
Create all required app files for a NEW text from:
1) a root verses TXT
2) a commentary DOCX with hierarchical section codes/headings

Inputs for this run:
TEXT_ID = <e.g. friendlyletter>
TITLE = <display title>
AUTHOR = <author label>
ROOT_TXT = texts/<text_id>/root_text.txt
COMMENTARY_DOCX = texts/<text_id>/<commentary file>.docx
QUIZ_BEGINNER_COUNT = 200
QUIZ_ADVANCED = false

Hard constraints (critical):
1. Preserve verse lines exactly from ROOT_TXT.
2. Do NOT split one verse into multiple verses.
3. Do NOT merge two verses.
4. Verse boundaries are ONLY lines that are integer verse numbers.
5. Keep internal line breaks exactly as-is in each verse.
6. Ignore appendix/glossary/endnote numbering in DOCX when mapping verses.
7. Section children in hierarchy must be numerically sorted by path tokens (so 3.1 appears before 3.2).

Required outputs:
1) texts/<text_id>/<text_id>_parsed.json
2) texts/<text_id>/verse_hierarchy_map.json
3) texts/<text_id>/verse_commentary_mapping.txt
4) texts/<text_id>/root_text_quiz.txt (beginner only, 200 questions, meaning-based)
5) Update lib/config/study_text_config.dart
6) Update pubspec.yaml assets list

File format requirements:
A) parsed.json keys: verses, captions, refs, chapters
B) verse_hierarchy_map.json keys: sections, verseToPath, sectionToFirstVerse
C) mapping format block:
   [1.x] [1.y]
   Section (<path>): <title> [<code>]
   <non-empty commentary snippet>
D) Quiz format:
   Qn. <meaning-based question tied to commentary>
   a) ...
   b) ...
   c) ...
   d) ...
   ANSWER: <a-d>
   VERSE REF(S): 1.x
   Use commentary meaning/structure, not “Which line appears...”.

Implementation requirements:
1. Parse ROOT_TXT first and build canonical verse dictionary.
2. Parse DOCX headings (including inline heading codes, not only line-start codes).
3. Restrict parsing to main commentary span; stop before appendices/glossary.
4. Accept a numeric verse marker only if nearby text matches canonical verse content (to filter footnotes/endnotes).
5. Build hierarchy from commentary codes and sort children by numeric path.
6. Map each verse ref exactly once in verseToPath.
7. sectionToFirstVerse must be subtree minimum verse.
8. Friendly behavior for quiz: beginner enabled, advanced omitted, guess_chapter disabled for this text.

Validation (must run and report):
1. Verse count in parsed.json == count in ROOT_TXT.
2. refs and captions counts match verses count.
3. Every verse 1..N appears exactly once in verseToPath.
4. No missing verse refs in mapping coverage.
5. Verify sorted order at all sibling nodes (especially brief vs extensive).
6. flutter analyze for changed Dart files.
7. Print a final audit summary with:
   a) verse count
   b) section count
   c) mapping block count
   d) quiz question count
   e) files changed

Do not stop at partial output. Implement files and code updates directly.
