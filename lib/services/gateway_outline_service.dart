class GatewayOutlineSection {
  const GatewayOutlineSection({
    required this.path,
    required this.title,
    required this.depth,
  });

  final String path;
  final String title;
  final int depth;
}

class GatewayOutlineChapter {
  const GatewayOutlineChapter({
    required this.number,
    required this.title,
    required this.sections,
  });

  final int number;
  final String title;
  final List<GatewayOutlineSection> sections;
}

class GatewayOutlineService {
  GatewayOutlineService._();

  static final GatewayOutlineService instance = GatewayOutlineService._();

  // Source: the original gateway-to-knowledge.html content in this repo.
  static const List<GatewayOutlineChapter> _chapters = <GatewayOutlineChapter>[
    GatewayOutlineChapter(
      number: 1,
      title: 'The Aggregates (Skandhas)',
      sections: <GatewayOutlineSection>[
        GatewayOutlineSection(path: '1.1', title: 'Five Aggregates', depth: 0),
        GatewayOutlineSection(
            path: '1.2', title: 'Aggregate of Form', depth: 0),
        GatewayOutlineSection(
            path: '1.3', title: 'Aggregate of Sensation', depth: 0),
        GatewayOutlineSection(
            path: '1.4', title: 'Aggregate of Perception', depth: 0),
        GatewayOutlineSection(
            path: '1.5', title: 'Aggregate of Formation', depth: 0),
        GatewayOutlineSection(
            path: '1.6', title: 'Non-current Formations', depth: 0),
        GatewayOutlineSection(
            path: '1.7', title: 'Aggregate of Consciousness', depth: 0),
      ],
    ),
    GatewayOutlineChapter(
      number: 2,
      title: 'The Elements (Dhatu)',
      sections: <GatewayOutlineSection>[
        GatewayOutlineSection(
            path: '2.1', title: 'Six Sense Triads at a Glance', depth: 0),
        GatewayOutlineSection(
            path: '2.2', title: 'Mental Object Sources (Ayatana)', depth: 0),
        GatewayOutlineSection(
            path: '2.3', title: 'Six Elements of a Person', depth: 0),
        GatewayOutlineSection(
            path: '2.4', title: 'Element Classifications', depth: 0),
      ],
    ),
    GatewayOutlineChapter(
      number: 3,
      title: 'The Sense Sources (Ayatana)',
      sections: <GatewayOutlineSection>[
        GatewayOutlineSection(
            path: '3.1',
            title: 'Inner and Outer Sources (Duality View)',
            depth: 0),
        GatewayOutlineSection(path: '3.2', title: 'Reference Table', depth: 0),
        GatewayOutlineSection(
            path: '3.3', title: 'The Five Bases of Knowables', depth: 0),
      ],
    ),
    GatewayOutlineChapter(
      number: 4,
      title: 'Dependent Origination',
      sections: <GatewayOutlineSection>[
        GatewayOutlineSection(
            path: '4.1', title: 'Seven Related Causes', depth: 0),
        GatewayOutlineSection(
            path: '4.2', title: 'Six Related Conditions', depth: 0),
        GatewayOutlineSection(
            path: '4.3',
            title: 'Twelve Links of Dependent Origination',
            depth: 0),
        GatewayOutlineSection(
            path: '4.4',
            title: 'First Subdivision of the Twelve Links',
            depth: 0),
        GatewayOutlineSection(
            path: '4.5',
            title: 'Second Subdivision of the Twelve Links',
            depth: 0),
        GatewayOutlineSection(
            path: '4.6',
            title: 'Third Subdivision of the Twelve Links',
            depth: 0),
        GatewayOutlineSection(
            path: '4.7',
            title: 'Fourth Subdivision of the Twelve Links',
            depth: 0),
      ],
    ),
  ];

  Future<List<GatewayOutlineChapter>> getChapters() async {
    return _chapters;
  }

  Future<GatewayOutlineChapter?> getChapter(int chapterNumber) async {
    for (final chapter in _chapters) {
      if (chapter.number == chapterNumber) return chapter;
    }
    return null;
  }
}
