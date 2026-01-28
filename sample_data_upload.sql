-- Sample data upload script
-- This shows how to structure your text data for upload to Supabase

-- Example: Insert a study text
INSERT INTO study_texts (title, full_text)
VALUES (
  'Your Study Text Title',
  'The complete text goes here...'
)
RETURNING id;

-- Use the returned ID from above as study_text_id below

-- Example: Insert chapters
INSERT INTO chapters (study_text_id, number, title)
VALUES 
  ('YOUR-STUDY-TEXT-ID-HERE', 1, 'Chapter One Title'),
  ('YOUR-STUDY-TEXT-ID-HERE', 2, 'Chapter Two Title'),
  ('YOUR-STUDY-TEXT-ID-HERE', 3, 'Chapter Three Title');

-- Example: Insert sections for Chapter 1
INSERT INTO sections (chapter_id, chapter_number, text)
VALUES 
  (
    (SELECT id FROM chapters WHERE number = 1),
    1,
    'This is the first section of chapter 1. It contains meaningful text that students will study.'
  ),
  (
    (SELECT id FROM chapters WHERE number = 1),
    1,
    'This is the second section of chapter 1. Each section should be a meaningful chunk of text.'
  );

-- Example: Insert sections for Chapter 2
INSERT INTO sections (chapter_id, chapter_number, text)
VALUES 
  (
    (SELECT id FROM chapters WHERE number = 2),
    2,
    'First section of chapter 2.'
  ),
  (
    (SELECT id FROM chapters WHERE number = 2),
    2,
    'Second section of chapter 2.'
  );

-- You can also use a Python script or other tool to parse your text file
-- and insert it programmatically. The key is to break it into:
-- 1. One study_text record
-- 2. Multiple chapter records (linked to study_text)
-- 3. Multiple section records (linked to chapters)
