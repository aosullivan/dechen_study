import 'gateway_outline_service.dart';

class GatewayRichBlock {
  const GatewayRichBlock({
    required this.type,
    this.text,
    this.items = const <String>[],
    this.headers = const <String>[],
    this.rows = const <List<String>>[],
    this.styleClass = '',
  });

  final String type;
  final String? text;
  final List<String> items;
  final List<String> headers;
  final List<List<String>> rows;
  final String styleClass;
}

class GatewayRichTopic {
  const GatewayRichTopic({
    required this.title,
    required this.blocks,
  });

  final String title;
  final List<GatewayRichBlock> blocks;
}

class GatewayRichChapter {
  const GatewayRichChapter({
    required this.number,
    required this.title,
    required this.topics,
  });

  final int number;
  final String title;
  final List<GatewayRichTopic> topics;
}

class GatewayRichContentService {
  GatewayRichContentService._();

  static final GatewayRichContentService instance = GatewayRichContentService._();

  static const List<GatewayRichChapter> _chapters = <GatewayRichChapter>[
    GatewayRichChapter(number: 1, title: 'The Aggregates (Skandhas)', topics: <GatewayRichTopic>[
      GatewayRichTopic(title: 'Five Aggregates', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'chip', text: 'Form', styleClass: 'pill icon-pill'),
        GatewayRichBlock(type: 'chip', text: 'Sensation', styleClass: 'pill icon-pill'),
        GatewayRichBlock(type: 'chip', text: 'Perceptions', styleClass: 'pill icon-pill'),
        GatewayRichBlock(type: 'chip', text: 'Formations', styleClass: 'pill icon-pill'),
        GatewayRichBlock(type: 'chip', text: 'Consciousness', styleClass: 'pill icon-pill'),
      ]),
      GatewayRichTopic(title: 'Aggregate of Form', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'p', text: 'Physical form includes:', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'ul', items: <String>['4 primary elements: earth, water, fire, wind.', '11 resultant forms: five sense faculties, five sense objects, and imperceptible form.'], styleClass: ''),
        GatewayRichBlock(type: 'p', text: 'In the Abhidharma Samuccaya, the five forms of mental objects are listed as:', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'ul', items: <String>['Deduced form', 'Spatial forms', 'Imperceptible forms (from taking a vow)', 'Imagined forms', 'Mastered forms through meditation'], styleClass: ''),
        GatewayRichBlock(type: 'p', text: 'Imperceptible form is described as:', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'ul', items: <String>['Imperceptible form after obtaining a vow', 'Imperceptible form arising from elements embraced by the stream of mind', 'A certain kind of physical or verbal action'], styleClass: ''),
        GatewayRichBlock(type: 'p', text: 'Form can be visible and obstructive, invisible and obstructive, or invisible and non-obstructive.', styleClass: 'callout'),
      ]),
      GatewayRichTopic(title: 'Aggregate of Sensation', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'p', text: 'Sensation is divided into pleasant, painful, and neutral. By support, there are 18 sensations: six senses multiplied by the three feeling tones.', styleClass: 'topic-copy'),
      ]),
      GatewayRichTopic(title: 'Aggregate of Perceptions', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'p', text: 'Six perceptions arise from contact. Six subdivisions are listed:', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'ol', items: <String>['Perceptions with characteristics (with three exceptions)', 'Perceptions without characteristics (those three exceptions)', 'Lesser perceptions (desire realm)', 'Vast perceptions (form realm)', 'Immeasurable perceptions', 'Perception of nothing whatsoever'], styleClass: ''),
      ]),
      GatewayRichTopic(title: 'Aggregate of Formations', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'p', text: 'Five ever-present mental states:', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'ul', items: <String>['Attraction', 'Sensation', 'Perception', 'Attention', 'Contact'], styleClass: ''),
        GatewayRichBlock(type: 'p', text: 'Five object-determining mental states:', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'ul', items: <String>['Intention', 'Interest', 'Recollection', 'Concentration', 'Discrimination'], styleClass: ''),
        GatewayRichBlock(type: 'p', text: 'These ten are called the Ten General Mind Bases.', styleClass: 'callout'),
        GatewayRichBlock(type: 'p', text: 'Eleven virtuous mental states:', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'ul', items: <String>['Faith', 'Conscientiousness', 'Pliancy', 'Equanimity', 'Conscience', 'Shame', 'Non-attachment', 'Non-aggression', 'Non-delusion', 'Non-violence', 'Diligence'], styleClass: ''),
        GatewayRichBlock(type: 'p', text: 'Root disturbing emotions (6): ignorance, attachment, anger, arrogance, doubt, belief.', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'p', text: 'Belief has 5 types:', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'ul', items: <String>['Belief in transitory collection', 'Belief of holding extremes', 'Perverted belief', 'Holding a belief to be paramount', 'Holding a discipline or ritual'], styleClass: ''),
        GatewayRichBlock(type: 'p', text: 'Twenty subsidiary disturbing emotions:', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'ol', items: <String>['Fury', 'Resentment', 'Spite', 'Hostility', 'Envy', 'Hypocrisy', 'Pretense', 'Lack of engagement', 'Shamelessness', 'Concealment', 'Stinginess', 'Self-infatuation', 'Lack of faith', 'Laziness', 'Heedlessness', 'Forgetfulness', 'Non-alertness', 'Lethargy', 'Excitement', 'Distraction'], styleClass: 'split-list'),
        GatewayRichBlock(type: 'p', text: 'Four variables: sleep, regret, conception, discernment.', styleClass: 'topic-copy'),
      ]),
      GatewayRichTopic(title: 'Non-current Formations', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'p', text: 'A quality newly obtained in a being (virtuous, non-virtuous, or neutral). Listed examples include:', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'ul', items: <String>['Dispossession', 'Same status or similar class', 'Perceptionless serenity', 'State of non-perception', 'Serenity of cessation', 'Ongoing all-ground not blocked by non-perception', 'Life faculty and life span of similar classes of beings'], styleClass: ''),
        GatewayRichBlock(type: 'p', text: 'Four characteristics of conditioned things: birth, subsistence, aging, impermanence.', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'p', text: 'Dharmas of formation: category of names, words, and letters.', styleClass: 'topic-copy'),
        GatewayRichBlock(type: 'p', text: 'Additional non-current formations: ordinary person, regular sequence, definitive distinctiveness, connected link, speed, sequence, time, location, number, gathering.', styleClass: 'topic-copy'),
      ]),
      GatewayRichTopic(title: 'Aggregate of Consciousness', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'p', text: 'Presented as seven categories: the mind element plus six consciousness elements.', styleClass: 'topic-copy'),
      ]),
    ]),
    GatewayRichChapter(number: 2, title: 'The Elements (Dhatu)', topics: <GatewayRichTopic>[
      GatewayRichTopic(title: 'Six Sense Triads at a Glance', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'ul', items: <String>['Eye Element', 'Ear Element', 'Nose Element', 'Tongue Element', 'Body Element', 'Mind Element'], styleClass: 'sense-list'),
        GatewayRichBlock(type: 'ul', items: <String>['Visual Form Element', 'Sound Element', 'Smell Element', 'Taste Element', 'Texture Element', 'Mental Object Element'], styleClass: 'sense-list'),
        GatewayRichBlock(type: 'ul', items: <String>['Eye Consciousness Element', 'Ear Consciousness Element', 'Nose Consciousness Element', 'Tongue Consciousness Element', 'Body Consciousness Element', 'Mind Consciousness Element'], styleClass: 'sense-list'),
      ]),
      GatewayRichTopic(title: 'Mental Object Sources (Ayatana)', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'ul', items: <String>['Three aggregates: sensation, perceptions, formations.', 'Five imperceptible forms (mental-object forms).', 'Unconditioned things: cessation due to discrimination, cessation not due to discrimination, space, suchness of virtue, suchness of non-virtue, suchness of neutral, occasion of blocked cognition during non-perception serenity, and occasion of blocked cognition during serenity of cessation.'], styleClass: ''),
      ]),
      GatewayRichTopic(title: 'Six Elements of a Person', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'chip', text: 'Earth', styleClass: 'pill icon-pill'),
        GatewayRichBlock(type: 'chip', text: 'Water', styleClass: 'pill icon-pill'),
        GatewayRichBlock(type: 'chip', text: 'Fire', styleClass: 'pill icon-pill'),
        GatewayRichBlock(type: 'chip', text: 'Wind', styleClass: 'pill icon-pill'),
        GatewayRichBlock(type: 'chip', text: 'Space', styleClass: 'pill icon-pill'),
        GatewayRichBlock(type: 'chip', text: 'Consciousness', styleClass: 'pill icon-pill'),
      ]),
      GatewayRichTopic(title: 'Element Classifications', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'ul', items: <String>['Elements with physical form: five sensory triads plus mental object element.', 'Mutually obstructive elements: five sense faculties and five sense objects.', 'Undefiling elements: mind element, mental object element, mind consciousness element, plus unconditioned things.', 'Desire realm elements: full set of six faculties, six objects, six consciousnesses.', 'Form realm elements: form-realm grouping of faculties, objects, and consciousnesses.', 'Formless realm elements: mind element, mental object element, mind consciousness element.', 'Outer elements: visual form, sound, smell, taste, texture, mental object element.', 'Elements with focus: six consciousness elements with mind and mental object.', 'Elements with concepts: mind element, mental object element, mind consciousness element.', 'Nine elements embraced by personal sensation: eye, ear, nose, tongue, body elements; smell, taste, texture, and mental object element.'], styleClass: ''),
      ]),
    ]),
    GatewayRichChapter(number: 3, title: 'The Sense Sources (Ayatana)', topics: <GatewayRichTopic>[
      GatewayRichTopic(title: 'Inner and Outer Sources (Duality View)', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'p', text: 'Sense sources are shown as a dual structure: what apprehends and what is apprehended.', styleClass: 'triad-note'),
        GatewayRichBlock(type: 'ul', items: <String>['Eye Source (Eye Element)', 'Ear Source (Ear Element)', 'Nose Source (Nose Element)', 'Tongue Source (Tongue Element)', 'Body Source (Body Element)', 'Mind Source (Seven Consciousness Elements)'], styleClass: 'duality-list'),
        GatewayRichBlock(type: 'ul', items: <String>['Visual Object Source (Visual Form Element)', 'Sound Object Source (Sound Element)', 'Olfactory Object Source (Smell Element)', 'Taste Object Source (Taste Element)', 'Tactile Object Source (Texture Element)', 'Mental Object Source (Mental Object Element)'], styleClass: 'duality-list'),
        GatewayRichBlock(type: 'p', text: 'Inner and outer sources work as a complementary pair: each inner source engages a corresponding outer source.', styleClass: 'callout'),
      ]),
      GatewayRichTopic(title: 'Reference Table', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'table', headers: <String>['Inner Sources (What Apprehends)', 'Outer Sources (What Is Apprehended)'], rows: <List<String>>[<String>['Eye Source (Eye Element)', 'Visual Object Source (Visual Form Element)'], <String>['Ear Source (Ear Element)', 'Sound Object Source (Sound Element)'], <String>['Nose Source (Nose Element)', 'Olfactory Object Source (Smell Element)'], <String>['Tongue Source (Tongue Element)', 'Taste Object Source (Taste Element)'], <String>['Body Source (Body Element)', 'Tactile Object Source (Texture Element)'], <String>['Mind Source (Seven Consciousness Elements)', 'Mental Object Source (Mental Object Element)']], styleClass: ''),
      ]),
      GatewayRichTopic(title: 'The Five Base Knowables', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'ol', items: <String>['Form base of appearance: the form aggregate.', 'Chief mind base: six or eight collections of consciousness (according to school).', 'Accompanying base of mental states: all mental states (51).', 'Non-current formations.', 'Base of unconditioned things: the mental object elements.'], styleClass: ''),
      ]),
    ]),
    GatewayRichChapter(number: 4, title: 'Dependent Origination', topics: <GatewayRichTopic>[
      GatewayRichTopic(title: 'Seven Related Causes', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'ul', items: <String>['Seed', 'Sprout', 'Stamen', 'Stalk', 'Bud', 'Flower', 'Fruit'], styleClass: 'icon-list-grid'),
      ]),
      GatewayRichTopic(title: 'Six Related Conditions', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'ul', items: <String>['Earth', 'Water', 'Fire', 'Wind', 'Space', 'Time'], styleClass: 'icon-list-grid'),
      ]),
      GatewayRichTopic(title: 'The Twelve Links of Dependent Origination', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'ol', items: <String>['Ignorance', 'Formation', 'Consciousness', 'Name and form', 'The six sense sources', 'Contact', 'Sensation', 'Craving', 'Grasping', 'Becoming', 'Rebirth', 'Old age and death'], styleClass: 'links-grid'),
      ]),
      GatewayRichTopic(title: 'First Subdivision of the Twelve Links', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'chip', text: 'Propelling Links', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'chip', text: 'Propelled Result', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'chip', text: 'Fully Establishing Links', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'chip', text: 'Fully Established Links', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'table', headers: <String>['Propelling Links', 'Propelled Result', 'Fully Establishing Links', 'Fully Established Links'], rows: <List<String>>[<String>['Ignorance', 'Name and Form', 'Craving', 'Rebirth'], <String>['Formation', 'The Six Sense Sources', 'Grasping', 'Old Age and Death'], <String>['Consciousness', 'Contact / Sensation', 'Becoming']], styleClass: ''),
      ]),
      GatewayRichTopic(title: 'Second Subdivision of the Twelve Links', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'chip', text: 'Affliction of Disturbing Emotions', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'chip', text: 'Affliction of Karma', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'chip', text: 'Affliction of Life', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'table', headers: <String>['Affliction of Disturbing Emotions', 'Affliction of Karma', 'Affliction of Life (Seven Bases of Suffering)'], rows: <List<String>>[<String>['Ignorance, Craving, Grasping', 'Formation, Becoming', 'Consciousness, Name and Form, Six Sense Sources, Contact, Sensation, Rebirth, Old Age and Death']], styleClass: ''),
        GatewayRichBlock(type: 'p', text: 'From the three disturbing emotions come two karmas; from these arise the seven bases of suffering.', styleClass: 'callout'),
      ]),
      GatewayRichTopic(title: 'Third Subdivision of the Twelve Links', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'chip', text: 'Truth of Origin', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'chip', text: 'Truth of Suffering', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'table', headers: <String>['Truth of Origin', 'Truth of Suffering'], rows: <List<String>>[<String>['Ignorance, Craving, Grasping, Formation, Becoming', 'Consciousness, Name and Form, Six Sense Sources, Contact, Sensation, Rebirth, Old Age and Death']], styleClass: ''),
      ]),
      GatewayRichTopic(title: 'Fourth Subdivision of the Twelve Links', blocks: <GatewayRichBlock>[
        GatewayRichBlock(type: 'chip', text: 'Truth of the Path', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'chip', text: 'Truth of Cessation', styleClass: 'subdivision-chip'),
        GatewayRichBlock(type: 'table', headers: <String>['Truth of the Path (reversal)', 'Truth of Cessation'], rows: <List<String>>[<String>['Ignorance, Craving, Grasping, Formation, Becoming', 'Consciousness, Name and Form, Six Sense Sources, Contact, Sensation, Rebirth, Old Age and Death']], styleClass: ''),
      ]),
    ]),
  ];

  Future<GatewayRichChapter?> getChapter(int chapterNumber) async {
    for (final chapter in _chapters) {
      if (chapter.number == chapterNumber) return chapter;
    }
    return null;
  }

  Future<List<GatewayOutlineChapter>> getOutlineChapters() {
    return GatewayOutlineService.instance.getChapters();
  }
}
