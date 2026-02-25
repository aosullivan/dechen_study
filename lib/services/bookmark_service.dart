import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's last reading position per text locally so the chapter-selection
/// screen can offer a "Resume Reading" shortcut.
class BookmarkService {
  BookmarkService._();
  static final instance = BookmarkService._();

  static String _keyVerseIndex(String textId) => 'bookmark_verse_index_$textId';
  static String _keyChapterNumber(String textId) => 'bookmark_chapter_number_$textId';
  static String _keyVerseRef(String textId) => 'bookmark_verse_ref_$textId';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Save the current reading position for [textId]. Called automatically as the user scrolls.
  Future<void> save(
    String textId, {
    required int verseIndex,
    required int chapterNumber,
    String? verseRef,
  }) async {
    final sp = await _sp;
    await sp.setInt(_keyVerseIndex(textId), verseIndex);
    await sp.setInt(_keyChapterNumber(textId), chapterNumber);
    if (verseRef != null) {
      await sp.setString(_keyVerseRef(textId), verseRef);
    }
  }

  /// Returns the saved bookmark for [textId], or null if the user has never read that text.
  Future<Bookmark?> load(String textId) async {
    final sp = await _sp;
    final verseIndex = sp.getInt(_keyVerseIndex(textId));
    final chapterNumber = sp.getInt(_keyChapterNumber(textId));
    if (verseIndex == null || chapterNumber == null) return null;
    return Bookmark(
      verseIndex: verseIndex,
      chapterNumber: chapterNumber,
      verseRef: sp.getString(_keyVerseRef(textId)),
    );
  }
}

class Bookmark {
  const Bookmark({
    required this.verseIndex,
    required this.chapterNumber,
    this.verseRef,
  });

  final int verseIndex;
  final int chapterNumber;

  /// Human-readable ref like "8.136", or null if unavailable.
  final String? verseRef;
}
