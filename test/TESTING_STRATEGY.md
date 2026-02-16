# Testing Strategy for Section Navigation

## Problem

The current unit tests pass but real-world behavior can be inconsistent:
- Key down from 2.37 sometimes jumps to 2.39 (skipping 2.38)
- Single key press sometimes triggers double navigation (2.38 → 2.39)

## What Tests Cover vs. What They Miss

### Unit tests (section_navigation_test.dart)

**Cover:**
- Service-layer logic: leaf order, verse order, findAdjacentSectionIndex
- Specific scenarios: 2.37→2.38, 8.114→8.115, etc.
- Data invariants: leaves sorted by first verse, no duplicate base verses

**Do not cover:**
- UI state: `_visibleVerseIndex`, `_currentSectionPath`, focus
- Visibility debounce: 150ms delay before breadcrumb updates
- Key repeat / double-fire from platform
- Race conditions: scroll → visibility update → stale `currentPath`

## Effective Testing Layers

### 1. Scenario-based unit tests (implemented)

Tests that use real hierarchy data for specific verses:

```
test('2.37 -> 2.38: leaf sequence is consecutive')
test('fallback from 2.37: findAdjacentSectionIndex returns 2.38 not 2.39')
test('reader leaf walk: no skips (2.34 to 2.38)')
```

When adding new verses or changing hierarchy, add tests for affected ranges.

### 2. Widget / integration tests (recommended)

Pump `BcvReadScreen`, set initial state, simulate `KeyDownEvent`, assert section changed:

```dart
// Pseudocode
testWidgets('key down from 2.37 navigates to 2.38', (tester) async {
  await tester.pumpWidget(MaterialApp(home: BcvReadScreen(scrollToVerseIndex: idx237)));
  await tester.pumpAndSettle();
  // Ensure reader has focus, currentPath = 3.2.1.3.1.3.4
  await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
  await tester.pumpAndSettle();
  // Assert breadcrumb/section shows 2.38
});
```

### 3. Manual test checklist

Run the app, open Bodhicaryavatara full text, then:

1. **2.37 → 2.38 (no skip)**
   - Navigate to verse 2.37 (e.g. Chapters panel → Chapter 2, or search).
   - Press Arrow Down 5 times. Each press should move to the next section.
   - Verify: first press goes to 2.38, never directly to 2.39.

2. **Single key press (no double-nav)**
   - At 2.37, press Arrow Down once.
   - Verify: you land on 2.38 only, not 2.38 then 2.39.

3. **Visibility lag**
   - Scroll to a verse, then immediately press Arrow Down (within ~200ms).
   - Verify: navigation goes to the correct next section (may be slightly wrong if visibility hasn’t updated).

4. **Section overview vs reader**
   - Click in the Section Overview panel (right side).
   - Press Arrow Down several times. Verify: moves through hierarchy (child sections), not verse order.
   - Click in the reader (main text). Press Arrow Down. Verify: moves by verse order (next leaf section).

## Root Causes of User-Reported Bugs

1. **Skip 2.38**: `_currentSectionPath` or `_visibleVerseIndex` wrong when key pressed (visibility debounce, or focus/state mismatch) → fallback `findAdjacentSectionIndex` used, which can skip if verses share first-verse or data edge case.

2. **Double navigation**: Key repeat or platform double-fire → fixed by 200ms debounce in `_debouncedArrowNav`.

3. **2.39 in leaf list**: 2.39 lives in section 3.1.1.3.5 whose first verse is 1.14ab, so 2.39 is not a leaf’s first verse. The leaf sequence 2.37→2.38→2.40... is correct; 2.39 is inside a larger section.
