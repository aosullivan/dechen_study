import 'package:flutter/material.dart';

import '../../services/bcv_verse_service.dart';
import '../../services/verse_hierarchy_service.dart';
import '../../utils/app_theme.dart';
import 'overview/overview_constants.dart';
import 'overview/overview_tree_view.dart';
import 'overview/overview_verse_panel.dart';

/// Full-screen hierarchical tree view of the entire text structure.
/// Cascading dropdown pickers at the top let you drill down level by level.
/// Tapping a section opens a side panel (desktop) or bottom sheet (mobile)
/// showing the verses for that section.
class TextualOverviewScreen extends StatefulWidget {
  const TextualOverviewScreen({super.key});

  @override
  State<TextualOverviewScreen> createState() => _TextualOverviewScreenState();
}

class _TextualOverviewScreenState extends State<TextualOverviewScreen> {
  bool _loading = true;
  List<({String path, String title, int depth})> _flatSections = [];

  String? _selectedPath;
  String? _selectedTitle;

  /// Cascading picker selections: index i holds the chosen path at depth i.
  List<String> _pickerSelections = [];

  /// Set when a picker changes — the tree scrolls to this path.
  String? _scrollToPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      BcvVerseService.instance.preload(),
      VerseHierarchyService.instance.preload(),
    ]);
    if (!mounted) return;
    setState(() {
      _flatSections = VerseHierarchyService.instance.getFlatSectionsSync();
      _loading = false;
    });
  }

  /// Returns children of [parentPath] (empty string = root-level sections).
  List<({String path, String title, int depth})> _childrenOf(
      String parentPath) {
    if (parentPath.isEmpty) {
      return _flatSections.where((s) => s.depth == 0).toList();
    }
    final parentDepth =
        _flatSections.where((s) => s.path == parentPath).firstOrNull?.depth;
    if (parentDepth == null) return [];
    final childDepth = parentDepth + 1;
    return _flatSections
        .where((s) =>
            s.depth == childDepth && s.path.startsWith('$parentPath.'))
        .toList();
  }

  static String _shortNum(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot + 1) : path;
  }

  void _onPickerChanged(int depth, String? path) {
    setState(() {
      // Truncate selections beyond this depth.
      if (_pickerSelections.length > depth) {
        _pickerSelections = _pickerSelections.sublist(0, depth);
      }
      if (path != null) {
        _pickerSelections.add(path);
        _scrollToPath = path;
        // Deeper pickers (depth > 0) also select the section to show verses.
        if (depth > 0) {
          _selectedPath = path;
          _selectedTitle = _flatSections
              .where((s) => s.path == path)
              .firstOrNull
              ?.title;
        } else {
          // Top-level picker just filters, doesn't select.
          _selectedPath = null;
          _selectedTitle = null;
        }
      } else {
        // "All" picked — clear selection.
        _selectedPath = null;
        _selectedTitle = null;
        _scrollToPath =
            _pickerSelections.isNotEmpty ? _pickerSelections.last : null;
      }
    });
  }

  /// Build picker selections from a section path.
  /// "4.3.2.1" -> ["4", "4.3", "4.3.2", "4.3.2.1"].
  /// Depth-0 nodes like "4" return ["4"].
  List<String> _pickerSelectionsForPath(String sectionPath) {
    final parts = sectionPath.split('.');
    final selections = <String>[];
    var prefix = '';
    for (final part in parts) {
      prefix = prefix.isEmpty ? part : '$prefix.$part';
      selections.add(prefix);
    }
    return selections;
  }

  void _onNodeTap(({String path, String title, int depth}) section) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= OverviewConstants.laptopBreakpoint;

    if (isDesktop) {
      setState(() {
        if (_selectedPath == section.path) {
          _selectedPath = null;
          _selectedTitle = null;
        } else {
          _selectedPath = section.path;
          _selectedTitle = section.title;
          _pickerSelections = _pickerSelectionsForPath(section.path);
        }
      });
    } else {
      setState(() {
        _selectedPath = section.path;
        _selectedTitle = section.title;
        _pickerSelections = _pickerSelectionsForPath(section.path);
      });
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.cardBeige,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => OverviewVersePanel(
            sectionPath: section.path,
            sectionTitle: section.title,
            scrollController: scrollController,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ).whenComplete(() {
        if (mounted) setState(() => _selectedPath = null);
      });
    }
  }

  /// Filtered flat sections: only the top-level picker (depth 0) filters.
  /// Deeper pickers just scroll, so the full subtree stays visible.
  List<({String path, String title, int depth})> get _filteredSections {
    if (_pickerSelections.isEmpty) return _flatSections;
    // Only filter by the first (top-level) selection.
    final root = _pickerSelections[0];
    final rootDepth =
        _flatSections.where((s) => s.path == root).firstOrNull?.depth ?? 0;
    return _flatSections
        .where((s) => s.path == root || s.path.startsWith('$root.'))
        .map((s) => (path: s.path, title: s.title, depth: s.depth - rootDepth))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Textual Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= OverviewConstants.laptopBreakpoint;

    return Column(
      children: [
        _buildPickers(),
        Expanded(
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(
                      child: OverviewTreeView(
                        flatSections: _filteredSections,
                        selectedPath: _selectedPath,
                        onNodeTap: _onNodeTap,
                        scrollToPath: _scrollToPath,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: _selectedPath != null
                          ? OverviewConstants.versePanelWidth
                          : 0,
                      child: _selectedPath != null
                          ? OverviewVersePanel(
                              key: ValueKey(_selectedPath),
                              sectionPath: _selectedPath!,
                              sectionTitle: _selectedTitle ?? '',
                              onClose: () => setState(() {
                                _selectedPath = null;
                                _selectedTitle = null;
                              }),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                )
              : OverviewTreeView(
                  flatSections: _filteredSections,
                  selectedPath: _selectedPath,
                  onNodeTap: _onNodeTap,
                  scrollToPath: _scrollToPath,
                ),
        ),
      ],
    );
  }

  Widget _buildPickers() {
    final pickers = <Widget>[];

    final rootChildren = _childrenOf('');
    if (rootChildren.isEmpty) return const SizedBox.shrink();

    pickers.add(_buildDropdownPicker(
      depth: 0,
      options: rootChildren,
      selectedPath:
          _pickerSelections.isNotEmpty ? _pickerSelections[0] : null,
    ));

    for (var i = 0; i < _pickerSelections.length; i++) {
      final children = _childrenOf(_pickerSelections[i]);
      if (children.isEmpty) break;
      pickers.add(_buildDropdownPicker(
        depth: i + 1,
        options: children,
        selectedPath: i + 1 < _pickerSelections.length
            ? _pickerSelections[i + 1]
            : null,
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.cardBeige,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < pickers.length; i++) ...[
            if (i > 0)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.mutedBrown),
            pickers[i],
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownPicker({
    required int depth,
    required List<({String path, String title, int depth})> options,
    required String? selectedPath,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPath,
          hint: Text(
            depth == 0 ? 'Section' : 'Subsection',
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 13,
              color: AppColors.mutedBrown,
            ),
          ),
          isDense: true,
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(Icons.expand_more,
                size: 18, color: AppColors.mutedBrown),
          ),
          style: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 13,
            color: AppColors.textDark,
          ),
          selectedItemBuilder: (context) {
            // The displayed selected value (compact, truncated).
            return [
              // "All" item:
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('All', style: TextStyle(
                  fontFamily: 'Lora', fontSize: 13,
                  color: AppColors.mutedBrown, fontStyle: FontStyle.italic,
                )),
              ),
              // Each option:
              ...options.map((s) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_shortNum(s.path)}. ${s.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lora', fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
              )),
            ];
          },
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text(
                'All',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 13,
                  color: AppColors.mutedBrown,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ...options.map((s) => DropdownMenuItem<String>(
                  value: s.path,
                  child: Text(
                    '${_shortNum(s.path)}. ${s.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: (value) {
            if (value == null || value.isEmpty) {
              _onPickerChanged(depth, null);
            } else {
              _onPickerChanged(depth, value);
            }
          },
        ),
      ),
    );
  }
}
