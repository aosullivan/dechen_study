import 'package:flutter/material.dart';

import '../../services/bcv_verse_service.dart';
import '../../services/verse_hierarchy_service.dart';
import '../../utils/app_theme.dart';
import 'overview/overview_constants.dart';
import 'overview/overview_tree_view.dart';
import 'overview/overview_verse_panel.dart';

/// Full-screen hierarchical tree view of the entire text structure.
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
        }
      });
    } else {
      // Mobile: show bottom sheet.
      setState(() {
        _selectedPath = section.path;
        _selectedTitle = section.title;
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

    if (!isDesktop) {
      return OverviewTreeView(
        flatSections: _flatSections,
        selectedPath: _selectedPath,
        onNodeTap: _onNodeTap,
      );
    }

    // Desktop: tree on left, verse panel on right.
    return Row(
      children: [
        Expanded(
          child: OverviewTreeView(
            flatSections: _flatSections,
            selectedPath: _selectedPath,
            onNodeTap: _onNodeTap,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _selectedPath != null ? OverviewConstants.versePanelWidth : 0,
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
    );
  }
}
