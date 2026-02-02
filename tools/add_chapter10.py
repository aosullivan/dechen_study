#!/usr/bin/env python3
"""
Script to add Chapter 10 to verse_commentary_mapping.txt
"""

import re

def main():
    # Read root verses from bcv-root
    with open('/Users/aosulliv/projects2/dechen_study/texts/bcv-root', 'r', encoding='utf-8') as f:
        root_lines = [l.rstrip() for l in f.readlines()[4299:4588]]
    
    # Read commentary
    with open('/Users/aosulliv/projects2/dechen_study/texts/commentary.txt', 'r', encoding='utf-8') as f:
        commentary_lines = [l.rstrip() for l in f.readlines()[8494:8968]]
    
    # Parse root verses - verse numbers are at the END of each verse
    root_verses = {}
    current_verse_text = []
    
    for line in root_lines:
        # Look for verse numbers at the end like [10.1]
        verse_match = re.search(r'\[(\d+\.\d+)\]', line)
        if verse_match:
            verse_num = verse_match.group(1)
            # Get text before the verse number
            text_before = line.split('[')[0].strip()
            if text_before:
                current_verse_text.append(text_before)
            if current_verse_text:
                root_verses[verse_num] = current_verse_text.copy()
            current_verse_text = []
        elif line.strip() and not line.startswith('Chapter'):
            current_verse_text.append(line)
    
    # Build normalized verse text sets for comparison
    verse_text_sets = {}
    for verse_num, lines in root_verses.items():
        verse_text_sets[verse_num] = [l.strip().lower() for l in lines if l.strip()]
    
    # Parse commentary and build output
    output_lines = []
    output_lines.append("Chapter 10: Dedication")
    output_lines.append("")
    
    i = 0
    while i < len(commentary_lines):
        line = commentary_lines[i]
        
        # Check for verse number (standalone line like "10.1")
        verse_match = re.match(r'^(\d+\.\d+)$', line)
        if verse_match:
            verse_num = verse_match.group(1)
            output_lines.append(verse_num)
            
            # Add root verse with >>> prefix
            if verse_num in root_verses:
                for root_line in root_verses[verse_num]:
                    if root_line.strip():
                        output_lines.append(f">>> {root_line}")
            
            # Collect commentary, skipping verse text
            i += 1
            commentary_text = []
            verse_lines_skipped = 0
            verse_text_to_skip = verse_text_sets.get(verse_num, [])
            
            while i < len(commentary_lines):
                next_line = commentary_lines[i]
                
                # Stop at next verse number
                if re.match(r'^\d+\.\d+$', next_line):
                    break
                
                # Skip page markers and headers
                if ('BODHICARYĀVATĀRA' in next_line or 
                    next_line.startswith('|') or 
                    re.match(r'^Dedication \d+$', next_line) or
                    next_line.startswith('CHAPTER') or
                    next_line.startswith('DEDICATION')):
                    i += 1
                    continue
                
                # Skip verse text lines that match root verse (they appear right after verse number)
                if verse_lines_skipped < len(verse_text_to_skip):
                    line_lower = next_line.strip().lower()
                    if line_lower in verse_text_to_skip:
                        verse_lines_skipped += 1
                        i += 1
                        continue
                
                if next_line.strip():
                    commentary_text.append(next_line)
                
                i += 1
            
            # Add commentary
            if commentary_text:
                commentary_combined = '\n'.join(commentary_text).strip()
                if commentary_combined:
                    output_lines.append(commentary_combined)
            
            output_lines.append("")
            continue
        
        i += 1
    
    # Read existing file and remove old Chapter 10
    with open('/Users/aosulliv/projects2/dechen_study/texts/verse_commentary_mapping.txt', 'r', encoding='utf-8') as f:
        existing_content = f.read()
    
    # Find and remove old Chapter 10
    lines = existing_content.split('\n')
    new_lines = []
    skip = False
    
    for i, line in enumerate(lines):
        if line.strip() == "Chapter 10: Dedication":
            skip = True
            continue
        if skip:
            # Check if we've hit a new chapter
            if line.strip().startswith("Chapter ") and "Chapter 10" not in line:
                skip = False
                new_lines.append(line)
            elif not skip:
                new_lines.append(line)
        else:
            new_lines.append(line)
    
    # Add new Chapter 10
    new_lines.extend(output_lines)
    
    # Write back
    with open('/Users/aosulliv/projects2/dechen_study/texts/verse_commentary_mapping.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))
        if not new_lines[-1]:  # Add final newline if not present
            f.write('\n')
    
    print(f"Updated Chapter 10 in verse_commentary_mapping.txt")
    print(f"Processed {len([l for l in output_lines if re.match(r'^\d+\.\d+$', l)])} verses")

if __name__ == '__main__':
    main()
