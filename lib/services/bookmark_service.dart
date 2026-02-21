import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's last reading position locally so the chapter-selection
/// screen can offer a "Resume Reading" shortcut.
class BookmarkService {
  BookmarkService._();
  static final instance = BookmarkService._();

  static const _keyVerseIndex = 'bookmark_verse_index';
  static const _keyChapterNumber = 'bookmark_chapter_number';
  static const _keyVerseRef = 'bookmark_verse_ref';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Save the current reading position.  Called automatically as the user
  /// scrolls through the text.
  Future<void> save({
    required int verseIndex,
    required int chapterNumber,
    String? verseRef,
  }) async {
    final sp = await _sp;
    await sp.setInt(_keyVerseIndex, verseIndex);
    await sp.setInt(_keyChapterNumber, chapterNumber);
    if (verseRef != null) {
      await sp.setString(_keyVerseRef, verseRef);
    }
  }

  /// Returns the saved bookmark, or null if the user has never read anything.
  Future<Bookmark?> load() async {
    final sp = await _sp;
    final verseIndex = sp.getInt(_keyVerseIndex);
    final chapterNumber = sp.getInt(_keyChapterNumber);
    if (verseIndex == null || chapterNumber == null) return null;
    return Bookmark(
      verseIndex: verseIndex,
      chapterNumber: chapterNumber,
      verseRef: sp.getString(_keyVerseRef),
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
