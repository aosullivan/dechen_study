#!/usr/bin/env python3
"""
Study Text Upload Helper Script

This script helps you parse a text file and upload it to your Supabase database.
It expects a text file with chapters marked by "Chapter N" or similar.

Usage:
    python upload_text.py your_text_file.txt

The script will:
1. Parse your text into chapters and sections
2. Generate SQL INSERT statements
3. Save the SQL to a file you can run in Supabase SQL Editor

You'll need to customize the parsing logic based on your text format.
"""

import re
import sys
import uuid

def parse_text_file(filepath):
    """
    Parse a text file into chapters and sections.
    
    Customize this function based on your text format.
    This example assumes:
    - Chapters are marked by "Chapter X" or "CHAPTER X"
    - Sections are separated by double newlines
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split by chapter markers
    chapter_pattern = r'(?:Chapter|CHAPTER)\s+(\d+)[:\s]*([^\n]*)'
    parts = re.split(chapter_pattern, content)
    
    chapters = []
    current_chapter = None
    
    for i in range(1, len(parts), 3):
        if i + 1 < len(parts):
            chapter_num = int(parts[i])
            chapter_title = parts[i + 1].strip()
            chapter_text = parts[i + 2] if i + 2 < len(parts) else ""
            
            # Split chapter into sections (by double newlines)
            sections = [s.strip() for s in chapter_text.split('\n\n') if s.strip()]
            
            chapters.append({
                'number': chapter_num,
                'title': chapter_title,
                'sections': sections
            })
    
    return chapters

def generate_sql(chapters, study_text_title):
    """Generate SQL INSERT statements for the parsed chapters."""
    
    # Generate UUIDs
    study_text_id = str(uuid.uuid4())
    
    sql = f"""-- Generated SQL for '{study_text_title}'
-- Run this in your Supabase SQL Editor

-- Insert the study text
INSERT INTO study_texts (id, title, full_text)
VALUES (
    '{study_text_id}',
    '{study_text_title}',
    'Full text will be assembled from chapters'
);

"""
    
    # Insert chapters and get their IDs
    for chapter in chapters:
        chapter_id = str(uuid.uuid4())
        
        # Escape single quotes in title
        safe_title = chapter['title'].replace("'", "''")
        
        sql += f"""-- Chapter {chapter['number']}
INSERT INTO chapters (id, study_text_id, number, title)
VALUES (
    '{chapter_id}',
    '{study_text_id}',
    {chapter['number']},
    '{safe_title}'
);

"""
        
        # Insert sections for this chapter
        for section_text in chapter['sections']:
            section_id = str(uuid.uuid4())
            # Escape single quotes in text
            safe_text = section_text.replace("'", "''")
            
            sql += f"""INSERT INTO sections (id, chapter_id, chapter_number, text)
VALUES (
    '{section_id}',
    '{chapter_id}',
    {chapter['number']},
    '{safe_text}'
);

"""
    
    return sql

def main():
    if len(sys.argv) < 2:
        print("Usage: python upload_text.py <text_file.txt>")
        print("\nThis script will parse your text file and generate SQL to upload it.")
        sys.exit(1)
    
    filepath = sys.argv[1]
    
    print(f"Parsing {filepath}...")
    chapters = parse_text_file(filepath)
    
    if not chapters:
        print("No chapters found! Check your text format.")
        print("Expected format: 'Chapter N' or 'CHAPTER N' to mark chapters")
        sys.exit(1)
    
    print(f"Found {len(chapters)} chapters:")
    for ch in chapters:
        print(f"  - Chapter {ch['number']}: {ch['title']} ({len(ch['sections'])} sections)")
    
    # Get study text title
    study_text_title = input("\nEnter a title for this study text: ").strip()
    if not study_text_title:
        study_text_title = "My Study Text"
    
    print("\nGenerating SQL...")
    sql = generate_sql(chapters, study_text_title)
    
    # Save to file
    output_file = "generated_upload.sql"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(sql)
    
    print(f"\n✅ SQL saved to {output_file}")
    print("\nNext steps:")
    print("1. Open Supabase SQL Editor")
    print(f"2. Copy the contents of {output_file}")
    print("3. Paste and run in SQL Editor")
    print("4. Your study text will be uploaded!")

if __name__ == '__main__':
    main()
