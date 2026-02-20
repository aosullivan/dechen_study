# Dechen Study

A study app for the Bodhicaryavatāra (Bodhisattvacaryāvatāra), built with Flutter and Supabase. Features include full-text reading with section hierarchy, daily verse sections, chapter quiz, commentary, and keyboard navigation.

## Features

- **Full Text Reading** – Browse the Bodhicaryavatāra organized by chapters, with verse-by-verse navigation
- **Section Hierarchy** – Commentary structure as parent/child sections; sections are subsets (children refine parents)
- **Section Overview** – Right-side panel listing the full section hierarchy; tap or use arrow keys to navigate
- **Keyboard Navigation** – Arrow Up/Down behave differently depending on focus (see below)
- **Daily Section** – One section per day with random selection
- **Chapter Quiz** – Identify which chapter a random section belongs to
- **Commentary** – Inline commentary for verses and sections
- **Email Authentication** – Sign up with confirmation

## Keyboard Navigation

The read screen has two distinct focus areas with different arrow-key behavior:

### Reader Pane (main text area)

When the **reader pane** has focus (click in the main text, or on first load):

- **Arrow Down** → Jump to the **next lowest-level section** (leaf section only)
- **Arrow Up** → Jump to the **previous lowest-level section** (leaf section only)

Navigation uses only leaf sections (sections with no children), in verse order. Each key press moves exactly one leaf section forward or backward—never to a parent section and never skipping sections.

### Section Overview (right panel)

When the **section overview** has focus (click in the section list panel):

- **Arrow Down** → Move to the **next item** in the hierarchy (depth-first order)
  - If the current section has children → go to the first child (smaller subset, may share verses)
  - If no children → go to next sibling or parent’s next sibling
  - Only when there is **no** next item in the hierarchy does it fall back to the next section in verse order
- **Arrow Up** → Move to the **previous item** in the hierarchy (reverse depth-first)

**Summary:** In the reader, arrow down always goes to a new set of verses. In the section overview, arrow down first explores children (more specific subsets); only when children are exhausted does it move to the next verse-ordered section.

## Prerequisites

- Flutter SDK (3.0+)
- Supabase account and project
- Fonts: Crimson Text, Lora (see Setup)

## Setup

### 1. Environment

Create a `.env` file in the project root:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 2. Fonts

Download and add to a `fonts/` directory:

- **Crimson Text** – [Google Fonts](https://fonts.google.com/specimen/Crimson+Text)
- **Lora** – [Google Fonts](https://fonts.google.com/specimen/Lora) (variable font)

Ensure `pubspec.yaml` font paths match your files.

### 3. Dependencies

```bash
flutter pub get
```

### 4. Build text assets

If you've cloned the repo, pre-built assets may already exist. If you change `texts/bcv-root` or pull changes that modify it, run:

```bash
dart run tools/build_bcv_parsed.dart
```

### 5. Run

```bash
flutter run
# or for web
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart
├── models/
│   └── study_models.dart
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   ├── daily_section_screen.dart
│   │   ├── quiz_screen.dart
│   │   └── read_screen.dart
│   └── landing/
│       ├── landing_screen.dart
│       ├── text_options_screen.dart
│       ├── daily_verse_screen.dart
│       ├── bcv_quiz_screen.dart
│       ├── bcv_read_screen.dart      # Full BCV reader with keyboard nav
│       └── bcv/
│           ├── bcv_chapters_panel.dart
│           └── bcv_section_slider.dart
├── services/
│   ├── auth_service.dart
│   ├── study_service.dart
│   ├── bcv_verse_service.dart        # Verse loading, chapter boundaries
│   ├── verse_hierarchy_service.dart  # Section hierarchy, navigation logic
│   └── commentary_service.dart
└── utils/
    ├── app_theme.dart
    └── constants.dart
```

## Text Assets

The app loads text from bundled assets:

- `texts/bcv-root` – Source root text (chapters, verses). Run `dart run tools/build_bcv_parsed.dart` to regenerate `texts/bcv_parsed.json` after changes.
- `texts/verse_hierarchy_map.json` – Canonical section hierarchy and verse mapping (source of truth; edit directly)
- `texts/verse_commentary_mapping.txt` – Verse-to-commentary mapping (includes commentary text)

## Hierarchy Maintenance

`texts/verse_hierarchy_map.json` is the source of truth. It is not generated in this repo.

When you change verse-section assignments, use this sequence:

```bash
# 1) Rebuild indices from the hierarchy tree
python3 script/rebuild_verse_indices.py

# 2) Audit empty leaf sections
node tools/audit_empty_leaves.js

# 3) Optional mismatch scan
dart run tools/audit_section_mismatches.dart
```

Audit outputs:

- `texts/empty_leaf_audit.md` – human-readable summary
- `texts/empty_leaf_audit.json` – machine-readable details

Notes:
- `texts/overviews-pages (EOS).txt` and `texts/verse_commentary_mapping.txt` remain useful for audit/comparison tooling.

Latest audit snapshot (from generated files):

- Generated: `2026-02-19T04:00:09.818Z`
- Total leaves: `738`
- Empty leaves: `98`
- Suspicious misassigned: `3`
- Ambiguous empty: `13`
- Expected empty: `82`
- Index inconsistencies: `0`
- Quoted-heading follow-up candidates: `0` (see `texts/expected_empty_quoted_candidates.json`)

## Tests

```bash
flutter test
# Section navigation tests
flutter test test/section_navigation_test.dart
```

## Design

- **Colors**: Warm browns (#8B7355), cream backgrounds (#FAF8F5)
- **Typography**: Crimson Text for headings, Lora for body
- **Layout**: Main reader + right panels (chapters, section overview, breadcrumb)

## License

MIT
