# Comprehensive Code Review: Duplication and Redundancy

## Executive summary

The codebase is structured clearly (services, screens, utils, models) and uses consistent patterns in many places. This review focuses on **duplication** and **redundant code** that could be consolidated to reduce maintenance cost and inconsistency risk. No critical bugs were identified; findings are refactoring opportunities.

---

## 1. Singleton pattern inconsistency

**Location:** All services in `lib/services/`.

**Finding:** Two styles are used:

- **Style A (private instance + getter):** `AuthService`, `StudyService`, `BcvVerseService`, `SectionClueService`, `CommentaryService`, `VerseHierarchyService` use `static final _instance = X._();` and `static X get instance => _instance;`
- **Style B (public instance):** `BookmarkService`, `BcvFileQuizService`, `GatewayOutlineService`, `UsageMetricsService` use `static final instance = X._();` (no getter)

**Recommendation:** Pick one style and apply it everywhere. Style A is slightly better for testability (getter can be overridden in tests if needed). Low priority.

---

## 2. Repeated "preload pair"

**Location:**
- [lib/screens/landing/landing_screen.dart](lib/screens/landing/landing_screen.dart) (initState)
- [lib/screens/landing/text_options_screen.dart](lib/screens/landing/text_options_screen.dart) (initState)
- [lib/screens/landing/textual_overview_screen.dart](lib/screens/landing/textual_overview_screen.dart) (_load)

**Finding:** The same two calls appear in three places:

```dart
BcvVerseService.instance.preload();
VerseHierarchyService.instance.preload();
```

In `textual_overview_screen.dart` they are part of a `Future.wait([...])`, but the intent is the same: warm BCV + hierarchy before use.

**Recommendation:** Add a small helper, e.g. in a shared place (e.g. `lib/utils/preload.dart` or on one of the services):

```dart
Future<void> preloadBcvAndHierarchy() async {
  await Future.wait([
    BcvVerseService.instance.preload(),
    VerseHierarchyService.instance.preload(),
  ]);
}
```

Then call `preloadBcvAndHierarchy()` from landing_screen, text_options_screen, and textual_overview_screen. This documents intent and keeps a single place to change if more services need preloading.

---

## 3. Auth screens: Login and SignUp

**Location:**
- [lib/screens/auth/login_screen.dart](lib/screens/auth/login_screen.dart)
- [lib/screens/auth/signup_screen.dart](lib/screens/auth/signup_screen.dart)

**Finding:**

- **Layout:** Both use the same structure: `Scaffold` -> `SafeArea` -> `Center` -> `SingleChildScrollView(padding: 24)` -> `ConstrainedBox(maxWidth: 400)` -> `Column` with title, subtitle, fields, primary button. Only the optional "Supabase not configured" banner and the "Don't have an account?" link differ on Login.
- **State:** Both use `_emailController`, `_passwordController`, `_authService`, `_isLoading`; SignUp adds `_confirmPasswordController`.
- **Error handling:** Both have `_showError(String message)` that shows a `SnackBar`. Login uses default SnackBar style; SignUp uses `backgroundColor: Colors.red.shade700`.
- **Submit flow:** Same pattern: validate -> set loading -> call service -> if (!mounted) return -> handle success/error -> set loading false.

**Recommendation:**

- Extract a shared **auth layout** widget that takes a list of children (title, subtitle, fields, buttons). Use it from both Login and SignUp.
- Optionally unify `_showError` (e.g. a shared helper or base mixin) and use a single style (e.g. always use `AppColors.darkBrown` or a shared "error" color from `AppColors`).
- Consider a small "auth form" helper that encapsulates: loading state, `_showError`, and the "try / if (!mounted) / finally" pattern so both screens call one method like `submitAuth(Future<AuthResponse> Function() action)`.

---

## 4. TextOptionsScreen: repeated "if bodhicaryavatara then track + push else coming soon"

**Location:** [lib/screens/landing/text_options_screen.dart](lib/screens/landing/text_options_screen.dart), methods `_openDaily`, `_openRead`, `_openReaderView`, `_openGuessTheChapter`, `_openQuiz`, `_openOverview`.

**Finding:** Each method repeats the same structure:

```dart
if (textId == 'bodhicaryavatara') {
  unawaited(UsageMetricsService.instance.trackTextOptionTapped(
    textId: textId,
    targetMode: '<mode>',
  ));
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SomeScreen(...)),
  );
} else {
  _showComingSoon(context, '<Feature>');
}
```

Only `targetMode` and the destination screen differ.

**Recommendation:** Introduce a helper, e.g.:

```dart
void _openBcvMode(
  BuildContext context, {
  required String targetMode,
  required Widget screen,
  required String comingSoonLabel,
}) {
  if (textId == 'bodhicaryavatara') {
    unawaited(UsageMetricsService.instance.trackTextOptionTapped(
      textId: textId,
      targetMode: targetMode,
    ));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  } else {
    _showComingSoon(context, comingSoonLabel);
  }
}
```

Then each "open" method becomes a one-liner calling `_openBcvMode` with the right `targetMode`, `screen`, and `comingSoonLabel`. Reduces duplication and makes adding new modes trivial.

---

## 5. LandingScreen: _openTextOptions and _openGatewayToKnowledge

**Location:** [lib/screens/landing/landing_screen.dart](lib/screens/landing/landing_screen.dart).

**Finding:** The two methods are almost identical:

- Call a path helper (`pushAppPath(...)`).
- Call `unawaited(UsageMetricsService.instance.trackEvent(eventName: 'text_opened', textId: ..., mode: 'text_options'))`.
- `Navigator.of(context).push(MaterialPageRoute(builder: (_) => SomeScreen(...)))`.

Only `textId` and the screen type differ.

**Recommendation:** Extract a single method, e.g.:

```dart
void _openText(BuildContext context, {required String textId, required Widget screen}) {
  pushAppPath(textId == 'gateway_to_knowledge' ? '/gateway-to-knowledge' : '/bodhicaryavatara');
  unawaited(UsageMetricsService.instance.trackEvent(
    eventName: 'text_opened',
    textId: textId,
    mode: 'text_options',
  ));
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}
```

Then `_openTextOptions` and `_openGatewayToKnowledge` become one-liners that call `_openText` with the appropriate `textId` and `screen`.

---

## 6. StudyService: repeated catch blocks

**Location:** [lib/services/study_service.dart](lib/services/study_service.dart).

**Finding:** Every method uses the same error pattern:

```dart
try {
  // ... supabase call ...
  return result;
} catch (e) {
  debugPrint('Error <operation>: $e');
  return null; // or [] or false
}
```

The only variations are the message string and the fallback value (null, [], false).

**Recommendation:** Add a private helper, e.g.:

```dart
Future<T?> _guard<T>(String operation, Future<T?> Function() fn) async {
  try {
    return await fn();
  } catch (e) {
    debugPrint('Error $operation: $e');
    return null;
  }
}
```

(And an overload or separate helper for `List`/`bool` fallbacks if you want to keep the same return types.) Then each method delegates to `_guard('fetching study text', () async { ... })`. This keeps logging consistent and makes it easier to add global error handling (e.g. reporting) later.

---

## 7. Lifecycle observer boilerplate

**Location:**
- [lib/screens/landing/bcv_read_screen.dart](lib/screens/landing/bcv_read_screen.dart)
- [lib/screens/landing/bcv_file_quiz_screen.dart](lib/screens/landing/bcv_file_quiz_screen.dart)
- [lib/screens/landing/bcv_quiz_screen.dart](lib/screens/landing/bcv_quiz_screen.dart)
- [lib/screens/landing/textual_overview_screen.dart](lib/screens/landing/textual_overview_screen.dart)
- [lib/screens/landing/daily_verse_screen.dart](lib/screens/landing/daily_verse_screen.dart)

**Finding:** Each screen does:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
}

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  // ... other dispose ...
  super.dispose();
}
```

and implements `WidgetsBindingObserver` to react to lifecycle (e.g. for usage metrics or pausing).

**Recommendation:** Consider a **mixin** that registers/unregisters the observer:

```dart
mixin WidgetLifecycleObserver on State {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

Screens that need lifecycle can use `with WidgetLifecycleObserver` and override `didChangeAppLifecycleState` (and similar) as needed. This removes repeated add/remove observer code; ensure `dispose` order is correct (observer removed before other cleanup).

---

## 8. WidgetsBinding.instance.addPostFrameCallback

**Location:** [lib/screens/landing/bcv_read_screen.dart](lib/screens/landing/bcv_read_screen.dart) (many call sites), [lib/screens/landing/gateway_landing_screen.dart](lib/screens/landing/gateway_landing_screen.dart), [lib/screens/landing/landing_screen.dart](lib/screens/landing/landing_screen.dart).

**Finding:** `addPostFrameCallback` is used in many places to defer work until after the current frame. In bcv_read_screen.dart it's used for scroll-to, focus, and state updates. The pattern is repeated but the *reason* (scroll vs focus vs state) differs.

**Recommendation:** No single abstraction is recommended; the callbacks are context-specific. If a given callback only does "schedule one-shot after frame," a local helper (e.g. `void _afterFrame(VoidCallback cb) => WidgetsBinding.instance.addPostFrameCallback((_) => cb());`) could shorten call sites slightly. Low priority; document in a short comment that "post-frame" is used to avoid layout/context issues.

---

## 9. Service "ensure loaded" pattern

**Location:**
- [lib/services/bcv_verse_service.dart](lib/services/bcv_verse_service.dart) (`_ensureLoaded`)
- [lib/services/section_clue_service.dart](lib/services/section_clue_service.dart) (`_ensureLoaded`)
- [lib/services/commentary_service.dart](lib/services/commentary_service.dart) (`_ensureLoaded`)
- [lib/services/verse_hierarchy_service.dart](lib/services/verse_hierarchy_service.dart) (`_ensureLoaded` / `preload()`)

**Finding:** Each service has its own `_ensureLoaded()` (or equivalent) that: checks a cache, loads an asset (or runs compute), and fills the cache. The logic differs (JSON shape, compute vs main thread, error handling), but the pattern is the same.

**Recommendation:** Treat this as a **pattern** rather than duplication. Extracting a generic "load once" helper would require passing in load logic and cache fields, which may not simplify the code much. Optional: add a one-line comment above each `_ensureLoaded` referring to "load-once pattern" so future readers recognize it. No code change required unless you introduce a shared cache/loader abstraction later.

---

## 10. Verse ref patterns (no duplication)

**Location:** [lib/services/bcv_verse_service.dart](lib/services/bcv_verse_service.dart) (`baseVerseRefPattern`, `segmentSuffixPattern`), used from verse_hierarchy_service, bcv_read_screen, daily_verse_screen, bcv_quiz_screen.

**Finding:** Verse ref parsing and validation are centralized in `BcvVerseService` (static RegExps and helpers). Other code reuses these; there is no duplicated regex or ref logic.

**Recommendation:** None; keep using these shared definitions.

---

## 11. Web navigation stub vs web implementation

**Location:** [lib/utils/web_navigation.dart](lib/utils/web_navigation.dart), [lib/utils/web_navigation_stub.dart](lib/utils/web_navigation_stub.dart), [lib/utils/web_navigation_web.dart](lib/utils/web_navigation_web.dart).

**Finding:** Conditional export is used correctly: one API surface, stub for non-web and real implementation for web. No duplication of business logic.

**Recommendation:** None.

---

## 12. Tests

**Location:** `test/*.dart`.

**Finding:** Test files use standard `flutter_test` style. Some tests share similar setup (e.g. `TestWidgetsFlutterBinding.ensureInitialized()`, `SharedPreferences.setMockInitialValues({})`). Test helpers are minimal; duplication is mostly in "pump and find" patterns, which is acceptable.

**Recommendation:** If more widget tests are added that need the same MaterialApp + preload or auth mock, consider a small test helper (e.g. `pumpBcvReadScreen(tester, ...)`) in a shared test file. Low priority.

---

## Summary table

| Area | Severity | Effort | Recommendation |
|------|-----------|--------|-----------------|
| Singleton style | Low | Low | Unify to one style (e.g. getter) across services |
| Preload pair | Medium | Low | Add `preloadBcvAndHierarchy()` and use in 3 places |
| Auth screens layout/error | Medium | Medium | Shared auth layout widget + optional submit helper |
| TextOptionsScreen open methods | High | Low | Single `_openBcvMode` helper |
| LandingScreen open methods | Medium | Low | Single `_openText` helper |
| StudyService catch blocks | Medium | Low | `_guard` (or similar) helper |
| Lifecycle observer | Low | Low | Mixin for add/remove observer |
| Post-frame callbacks | Low | Low | Optional local helper; document intent |
| Service _ensureLoaded | N/A | - | Keep as-is; optional comment |
| Verse ref patterns | N/A | - | No change |
| Web navigation | N/A | - | No change |

---

## Suggested order of work

1. **High impact, low effort:** TextOptionsScreen `_openBcvMode` (and optionally LandingScreen `_openText` + StudyService `_guard`).
2. **Medium impact, low effort:** Preload helper; singleton style if desired.
3. **Medium impact, medium effort:** Auth layout and/or submit helper.
4. **Low impact:** Lifecycle mixin; post-frame helper/docs.

This order improves clarity and reduces copy-paste first, then tackles slightly larger refactors (auth) when convenient.
