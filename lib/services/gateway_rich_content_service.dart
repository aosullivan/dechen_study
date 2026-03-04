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

  static final GatewayRichContentService instance =
      GatewayRichContentService._();

  static const List<GatewayRichChapter> _chapters = <GatewayRichChapter>[
    GatewayRichChapter(
        number: 1,
        title: 'The Aggregates',
        topics: <GatewayRichTopic>[
          GatewayRichTopic(title: 'Five Aggregates', blocks: <GatewayRichBlock>[
            GatewayRichBlock(
                type: 'chip', text: 'Form', styleClass: 'pill icon-pill'),
            GatewayRichBlock(
                type: 'chip', text: 'Sensation', styleClass: 'pill icon-pill'),
            GatewayRichBlock(
                type: 'chip',
                text: 'Perceptions',
                styleClass: 'pill icon-pill'),
            GatewayRichBlock(
                type: 'chip', text: 'Formations', styleClass: 'pill icon-pill'),
            GatewayRichBlock(
                type: 'chip',
                text: 'Consciousness',
                styleClass: 'pill icon-pill'),
          ]),
          GatewayRichTopic(
              title: 'Aggregate of Form',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'p',
                    text: 'Physical form includes:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '4 primary elements: earth, water, fire, wind.',
                      '11 resultant forms: five sense-faculty dhatus, five sense-object dhatus, and imperceptible form.'
                    ],
                    styleClass: ''),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'In the Abhidharma Samuccaya, the five forms of mental objects are listed as:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Deduced form',
                      'Spatial forms',
                      'Imperceptible forms (from taking a vow)',
                      'Imagined forms',
                      'Mastered forms through meditation'
                    ],
                    styleClass: ''),
                GatewayRichBlock(
                    type: 'p',
                    text: 'Imperceptible form is described as:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Imperceptible form after obtaining a vow',
                      'Imperceptible form arising from elements embraced by the stream of mind',
                      'A certain kind of physical or verbal action'
                    ],
                    styleClass: 'inner-list'),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Form can be visible and obstructive, invisible and obstructive, or invisible and non-obstructive.',
                    styleClass: 'callout'),
              ]),
          GatewayRichTopic(
              title: 'Aggregate of Sensation',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Sensation is divided into pleasant, painful, and neutral. By support, there are 18 sensations: six senses multiplied by the three feeling tones.',
                    styleClass: 'topic-copy'),
              ]),
          GatewayRichTopic(
              title: 'Aggregate of Perceptions',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Six perceptions arise from contact. Six subdivisions are listed:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ol',
                    items: <String>[
                      'Perceptions with characteristics (with three exceptions)',
                      'Perceptions without characteristics (those three exceptions)',
                      'Lesser perceptions (desire realm)',
                      'Vast perceptions (form realm)',
                      'Immeasurable perceptions',
                      'Perception of nothing whatsoever'
                    ],
                    styleClass: ''),
              ]),
          GatewayRichTopic(
              title: 'Aggregate of Formations',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'p',
                    text: 'Five ever-present mental states:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Attraction',
                      'Sensation',
                      'Perception',
                      'Attention',
                      'Contact'
                    ],
                    styleClass: ''),
                GatewayRichBlock(
                    type: 'p',
                    text: 'Five object-determining mental states:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Intention',
                      'Interest',
                      'Recollection',
                      'Concentration',
                      'Discrimination'
                    ],
                    styleClass: ''),
                GatewayRichBlock(
                    type: 'p',
                    text: 'These ten are called the Ten General Mind Bases.',
                    styleClass: 'callout'),
                GatewayRichBlock(
                    type: 'p',
                    text: 'Eleven virtuous mental states:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Faith',
                      'Conscientiousness',
                      'Pliancy',
                      'Equanimity',
                      'Conscience',
                      'Shame',
                      'Non-attachment',
                      'Non-aggression',
                      'Non-delusion',
                      'Non-violence',
                      'Diligence'
                    ],
                    styleClass: ''),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Root disturbing emotions (6): ignorance, attachment, anger, arrogance, doubt, belief.',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'p',
                    text: 'Belief has 5 types:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Belief in transitory collection',
                      'Belief of holding extremes',
                      'Perverted belief',
                      'Holding a belief to be paramount',
                      'Holding a discipline or ritual'
                    ],
                    styleClass: ''),
                GatewayRichBlock(
                    type: 'p',
                    text: 'Twenty subsidiary disturbing emotions:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ol',
                    items: <String>[
                      'Fury',
                      'Resentment',
                      'Spite',
                      'Hostility',
                      'Envy',
                      'Hypocrisy',
                      'Pretense',
                      'Lack of engagement',
                      'Shamelessness',
                      'Concealment',
                      'Stinginess',
                      'Self-infatuation',
                      'Lack of faith',
                      'Laziness',
                      'Heedlessness',
                      'Forgetfulness',
                      'Non-alertness',
                      'Lethargy',
                      'Excitement',
                      'Distraction'
                    ],
                    styleClass: 'split-list'),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Four variables: sleep, regret, conception, discernment.',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'p',
                    text: 'Non-current Formations',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'A quality newly obtained in a being (virtuous, non-virtuous, or neutral). Listed examples include:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Dispossession',
                      'Same status or similar class',
                      'Perceptionless serenity',
                      'State of non-perception',
                      'Serenity of cessation',
                      'Ongoing all-ground not blocked by non-perception',
                      'Life faculty and life span of similar classes of beings'
                    ],
                    styleClass: ''),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Four characteristics of conditioned things: birth, subsistence, aging, impermanence.',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Dharmas of formation: category of names, words, and letters.',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Additional non-current formations: ordinary person, regular sequence, definitive distinctiveness, connected link, speed, sequence, time, location, number, gathering.',
                    styleClass: 'topic-copy'),
              ]),
          GatewayRichTopic(
              title: 'Aggregate of Consciousness',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Presented as seven categories: the mind element plus six consciousness elements.',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Mind Element',
                      'Eye Consciousness Element',
                      'Ear Consciousness Element',
                      'Nose Consciousness Element',
                      'Tongue Consciousness Element',
                      'Body Consciousness Element',
                      'Mind Consciousness Element',
                    ],
                    styleClass: 'consciousness-stack'),
              ]),
        ]),
    GatewayRichChapter(
        number: 2,
        title: 'The Elements',
        topics: <GatewayRichTopic>[
          GatewayRichTopic(title: 'Eighteen Dhatus', blocks: <GatewayRichBlock>[
            GatewayRichBlock(
                type: 'ul',
                items: <String>[
                  'Eye Element',
                  'Ear Element',
                  'Nose Element',
                  'Tongue Element',
                  'Body Element',
                  'Mind Element'
                ],
                styleClass: 'sense-list'),
            GatewayRichBlock(
                type: 'ul',
                items: <String>[
                  'Visual Form Element',
                  'Sound Element',
                  'Smell Element',
                  'Taste Element',
                  'Texture Element',
                  'Mental Object Element'
                ],
                styleClass: 'sense-list'),
            GatewayRichBlock(
                type: 'ul',
                items: <String>[
                  'Eye Consciousness Element',
                  'Ear Consciousness Element',
                  'Nose Consciousness Element',
                  'Tongue Consciousness Element',
                  'Body Consciousness Element',
                  'Mind Consciousness Element'
                ],
                styleClass: 'sense-list'),
            // --- Aggregate of Form ---
            GatewayRichBlock(
                type: 'p',
                text: 'The Aggregate of Forms',
                styleClass: 'subset-title'),
            GatewayRichBlock(
                type: 'ul',
                items: <String>[
                  'Eye Element',
                  'Ear Element',
                  'Nose Element',
                  'Tongue Element',
                  'Body Element',
                  '~Mind Element'
                ],
                styleClass: 'sense-list-subset'),
            GatewayRichBlock(
                type: 'ul',
                items: <String>[
                  'Visual Form Element',
                  'Sound Element',
                  'Smell Element',
                  'Taste Element',
                  'Texture Element',
                  '~Mental Object Element'
                ],
                styleClass: 'sense-list-subset'),
            GatewayRichBlock(
                type: 'ul',
                items: <String>[
                  '~Eye Consciousness Element',
                  '~Ear Consciousness Element',
                  '~Nose Consciousness Element',
                  '~Tongue Consciousness Element',
                  '~Body Consciousness Element',
                  '~Mind Consciousness Element'
                ],
                styleClass: 'sense-list-subset'),
            // --- Aggregate of Consciousness ---
            GatewayRichBlock(
                type: 'p',
                text: 'The Aggregate of Consciousness',
                styleClass: 'subset-title'),
            GatewayRichBlock(
                type: 'ul',
                items: <String>[
                  '~Eye Element',
                  '~Ear Element',
                  '~Nose Element',
                  '~Tongue Element',
                  '~Body Element',
                  'Mind Element'
                ],
                styleClass: 'sense-list-subset'),
            GatewayRichBlock(
                type: 'ul',
                items: <String>[
                  '~Visual Form Element',
                  '~Sound Element',
                  '~Smell Element',
                  '~Taste Element',
                  '~Texture Element',
                  '~Mental Object Element'
                ],
                styleClass: 'sense-list-subset'),
            GatewayRichBlock(
                type: 'ul',
                items: <String>[
                  'Eye Consciousness Element',
                  'Ear Consciousness Element',
                  'Nose Consciousness Element',
                  'Tongue Consciousness Element',
                  'Body Consciousness Element',
                  'Mind Consciousness Element'
                ],
                styleClass: 'sense-list-subset'),
          ]),
          GatewayRichTopic(
              title: 'Mental Object Sources (Ayatana)',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Three aggregates: sensation, perceptions, formations.',
                      'Five imperceptible forms (mental-object forms).',
                      'Unconditioned things: cessation due to discrimination, cessation not due to discrimination, space, suchness of virtue, suchness of non-virtue, suchness of neutral, occasion of blocked cognition during non-perception serenity, and occasion of blocked cognition during serenity of cessation.'
                    ],
                    styleClass: ''),
              ]),
          GatewayRichTopic(
              title: 'Six Elements of a Person',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'chip', text: 'Earth', styleClass: 'pill icon-pill'),
                GatewayRichBlock(
                    type: 'chip', text: 'Water', styleClass: 'pill icon-pill'),
                GatewayRichBlock(
                    type: 'chip', text: 'Fire', styleClass: 'pill icon-pill'),
                GatewayRichBlock(
                    type: 'chip', text: 'Wind', styleClass: 'pill icon-pill'),
                GatewayRichBlock(
                    type: 'chip', text: 'Space', styleClass: 'pill icon-pill'),
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Consciousness',
                    styleClass: 'pill icon-pill'),
              ]),
          GatewayRichTopic(
              title: 'Element Classifications',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Elements with physical form: five sense faculties plus mental object element.',
                      'Mutually obstructive elements: five sense faculties and five sense objects.',
                      'Undefiling elements: mind element, mental object element, mind consciousness element, plus unconditioned things.',
                      'Desire realm elements: full set of six faculties, six objects, six consciousnesses.',
                      'Form realm elements: form-realm grouping of faculties, objects, and consciousnesses.',
                      'Formless realm elements: mind element, mental object element, mind consciousness element.',
                      'Outer elements: visual form, sound, smell, taste, texture, mental object element.',
                      'Elements with focus: six consciousness elements with mind and mental object.',
                      'Elements with concepts: mind element, mental object element, mind consciousness element.',
                      'Nine elements embraced by personal sensation: eye, ear, nose, tongue, body elements; smell, taste, texture, and mental object element.'
                    ],
                    styleClass: 'classification-summary'),
                // --- Elements with Physical Form ---
                GatewayRichBlock(
                    type: 'p',
                    text: 'Elements with Physical Form',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Eye Element',
                      'Ear Element',
                      'Nose Element',
                      'Tongue Element',
                      'Body Element',
                      '~Mind Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Visual Form Element',
                      'Sound Element',
                      'Smell Element',
                      'Taste Element',
                      'Texture Element',
                      'Mental Object Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Consciousness Element',
                      '~Ear Consciousness Element',
                      '~Nose Consciousness Element',
                      '~Tongue Consciousness Element',
                      '~Body Consciousness Element',
                      '~Mind Consciousness Element'
                    ],
                    styleClass: 'sense-list-subset'),
                // --- Mutually Obstructive Elements ---
                GatewayRichBlock(
                    type: 'p',
                    text: 'Mutually Obstructive Elements',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Eye Element',
                      'Ear Element',
                      'Nose Element',
                      'Tongue Element',
                      'Body Element',
                      '~Mind Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Visual Form Element',
                      'Sound Element',
                      'Smell Element',
                      'Taste Element',
                      'Texture Element',
                      '~Mental Object Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Consciousness Element',
                      '~Ear Consciousness Element',
                      '~Nose Consciousness Element',
                      '~Tongue Consciousness Element',
                      '~Body Consciousness Element',
                      '~Mind Consciousness Element'
                    ],
                    styleClass: 'sense-list-subset'),
                // --- Undefiling Elements ---
                GatewayRichBlock(
                    type: 'p',
                    text: 'Undefiling Elements',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Element',
                      '~Ear Element',
                      '~Nose Element',
                      '~Tongue Element',
                      '~Body Element',
                      'Mind Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Visual Form Element',
                      '~Sound Element',
                      '~Smell Element',
                      '~Taste Element',
                      '~Texture Element',
                      'Mental Object Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Consciousness Element',
                      '~Ear Consciousness Element',
                      '~Nose Consciousness Element',
                      '~Tongue Consciousness Element',
                      '~Body Consciousness Element',
                      'Mind Consciousness Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'p',
                    text: 'Plus the Unconditioned Things',
                    styleClass: 'subset-note'),
                // --- Desire Realm Elements ---
                GatewayRichBlock(
                    type: 'p',
                    text: 'Desire Realm Elements',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Eye Element',
                      'Ear Element',
                      'Nose Element',
                      'Tongue Element',
                      'Body Element',
                      'Mind Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Visual Form Element',
                      'Sound Element',
                      'Smell Element',
                      'Taste Element',
                      'Texture Element',
                      'Mental Object Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Eye Consciousness Element',
                      'Ear Consciousness Element',
                      'Nose Consciousness Element',
                      'Tongue Consciousness Element',
                      'Body Consciousness Element',
                      'Mind Consciousness Element'
                    ],
                    styleClass: 'sense-list-subset'),
                // --- Form Realm Elements ---
                GatewayRichBlock(
                    type: 'p',
                    text: 'Form Realm Elements',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Eye Element',
                      'Ear Element',
                      '~Nose Element',
                      '~Tongue Element',
                      'Body Element',
                      'Mind Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Visual Form Element',
                      'Sound Element',
                      '~Smell Element',
                      '~Taste Element',
                      'Texture Element',
                      'Mental Object Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Eye Consciousness Element',
                      'Ear Consciousness Element',
                      'Nose Consciousness Element',
                      'Tongue Consciousness Element',
                      'Body Consciousness Element',
                      'Mind Consciousness Element'
                    ],
                    styleClass: 'sense-list-subset'),
                // --- Formless Realm Elements ---
                GatewayRichBlock(
                    type: 'p',
                    text: 'Formless Realm Elements',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Element',
                      '~Ear Element',
                      '~Nose Element',
                      '~Tongue Element',
                      '~Body Element',
                      'Mind Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Visual Form Element',
                      '~Sound Element',
                      '~Smell Element',
                      '~Taste Element',
                      '~Texture Element',
                      'Mental Object Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Consciousness Element',
                      '~Ear Consciousness Element',
                      '~Nose Consciousness Element',
                      '~Tongue Consciousness Element',
                      '~Body Consciousness Element',
                      'Mind Consciousness Element'
                    ],
                    styleClass: 'sense-list-subset'),
                // --- Outer Elements ---
                GatewayRichBlock(
                    type: 'p',
                    text: 'Outer Elements',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Element',
                      '~Ear Element',
                      '~Nose Element',
                      '~Tongue Element',
                      '~Body Element',
                      '~Mind Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Visual Form Element',
                      'Sound Element',
                      'Smell Element',
                      'Taste Element',
                      'Texture Element',
                      'Mental Object Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Consciousness Element',
                      '~Ear Consciousness Element',
                      '~Nose Consciousness Element',
                      '~Tongue Consciousness Element',
                      '~Body Consciousness Element',
                      '~Mind Consciousness Element'
                    ],
                    styleClass: 'sense-list-subset'),
                // --- Elements with Focus ---
                GatewayRichBlock(
                    type: 'p',
                    text: 'Elements with Focus',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Element',
                      '~Ear Element',
                      '~Nose Element',
                      '~Tongue Element',
                      '~Body Element',
                      'Mind Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Visual Form Element',
                      '~Sound Element',
                      '~Smell Element',
                      '~Taste Element',
                      '~Texture Element',
                      'Mental Object Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Eye Consciousness Element',
                      'Ear Consciousness Element',
                      'Nose Consciousness Element',
                      'Tongue Consciousness Element',
                      'Body Consciousness Element',
                      'Mind Consciousness Element'
                    ],
                    styleClass: 'sense-list-subset'),
                // --- Elements with Concepts ---
                GatewayRichBlock(
                    type: 'p',
                    text: 'Elements with Concepts',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Element',
                      '~Ear Element',
                      '~Nose Element',
                      '~Tongue Element',
                      '~Body Element',
                      'Mind Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Visual Form Element',
                      '~Sound Element',
                      '~Smell Element',
                      '~Taste Element',
                      '~Texture Element',
                      'Mental Object Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Consciousness Element',
                      '~Ear Consciousness Element',
                      '~Nose Consciousness Element',
                      '~Tongue Consciousness Element',
                      '~Body Consciousness Element',
                      'Mind Consciousness Element'
                    ],
                    styleClass: 'sense-list-subset'),
                // --- Nine Elements Embraced by Personal Sensation ---
                GatewayRichBlock(
                    type: 'p',
                    text: 'Nine Elements Embraced by Personal Sensation',
                    styleClass: 'subset-title'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Eye Element',
                      'Ear Element',
                      'Nose Element',
                      'Tongue Element',
                      'Body Element',
                      '~Mind Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Visual Form Element',
                      '~Sound Element',
                      'Smell Element',
                      'Taste Element',
                      'Texture Element',
                      'Mental Object Element'
                    ],
                    styleClass: 'sense-list-subset'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      '~Eye Consciousness Element',
                      '~Ear Consciousness Element',
                      '~Nose Consciousness Element',
                      '~Tongue Consciousness Element',
                      '~Body Consciousness Element',
                      '~Mind Consciousness Element'
                    ],
                    styleClass: 'sense-list-subset'),
              ]),
          GatewayRichTopic(
              title: 'Classification Overlaps',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'The ten classifications above overlap in structured ways. Tap any element or classification to see how it relates to the others.',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(type: 'classification-matrix', styleClass: ''),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Mental Object belongs to 9 of 10 classifications — every set except Mutually Obstructive. It uniquely bridges the material side (Physical Form, Outer) with the mental side (Formless, Concepts, Focus).',
                    styleClass: 'callout'),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Formless Realm and Elements with Concepts contain exactly the same three dhatus: Mind Faculty, Mental Object, and Mind Consciousness. Undefiling adds unconditioned things beyond the 18 dhatus.',
                    styleClass: 'callout'),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'Mind Faculty and Mind Consciousness have identical classification membership across all 10 sets, despite being in different triads (faculty vs. consciousness).',
                    styleClass: 'callout'),
              ]),
        ]),
    GatewayRichChapter(
        number: 3,
        title: 'The Sense Sources',
        topics: <GatewayRichTopic>[
          GatewayRichTopic(
              title: 'Inner and Outer Sources',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Eye Source',
                      'Ear Source',
                      'Nose Source',
                      'Tongue Source',
                      'Body Source',
                      'Mind Source'
                    ],
                    styleClass: 'duality-list'),
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Visual Object Source',
                      'Sound Object Source',
                      'Olfactory Object Source',
                      'Taste Object Source',
                      'Tactile Object Source',
                      'Mental Object Source'
                    ],
                    styleClass: 'duality-list'),
              ]),
          GatewayRichTopic(
              title: 'Mapping Ayatanas to Dhatus',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'The 12 ayatanas and the 18 dhatus overlap extensively. The dhatus expand on the ayatanas by splitting the Mind Source into its constituent consciousness elements and adding the Mind Faculty Element.',
                    styleClass: 'triad-note'),
                GatewayRichBlock(
                    type: 'table',
                    headers: <String>['12 Ayatanas', '18 Dhatus'],
                    rows: <List<String>>[
                      <String>['Eye Source', 'Eye Element'],
                      <String>['Ear Source', 'Ear Element'],
                      <String>['Nose Source', 'Nose Element'],
                      <String>['Tongue Source', 'Tongue Element'],
                      <String>['Body Source', 'Body Element'],
                      <String>['Visual Object Source', 'Visual Form Element'],
                      <String>['Sound Object Source', 'Sound Element'],
                      <String>['Olfactory Object Source', 'Smell Element'],
                      <String>['Taste Object Source', 'Taste Element'],
                      <String>['Tactile Object Source', 'Texture Element'],
                      <String>['Mental Object Source', 'Mental Object Element'],
                      <String>[
                        'Mind Source',
                        'Mind Element + 6 Consciousness Elements'
                      ]
                    ],
                    styleClass: 'ayatana-dhatu-map'),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'The 5 inner ayatanas (Eye, Ear, Nose, Tongue, Body) match the first 5 faculty elements directly. The 6 outer ayatanas match the 6 object elements. The 6 consciousness elements plus the Mind Faculty Element all map to the single Mind Source ayatana.',
                    styleClass: 'callout'),
              ]),
          GatewayRichTopic(
              title: 'The Five Base Knowables',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'p',
                    text: 'All phenomena can be classified into five bases:',
                    styleClass: 'topic-copy'),
                GatewayRichBlock(
                    type: 'ol',
                    items: <String>[
                      'Form base of appearance: the form aggregate.',
                      'Chief mind base: six or eight collections of consciousness (according to school).',
                      'Accompanying base of mental states: all mental states (51).',
                      'Non-current formations.',
                      'Base of unconditioned things: the mental object elements.'
                    ],
                    styleClass: 'links-compact'),
              ]),
        ]),
    GatewayRichChapter(
        number: 4,
        title: 'Dependent Origination',
        topics: <GatewayRichTopic>[
          GatewayRichTopic(
              title: 'Seven Related Causes',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Seed',
                      'Sprout',
                      'Stamen',
                      'Stalk',
                      'Bud',
                      'Flower',
                      'Fruit'
                    ],
                    styleClass: 'icon-list-grid'),
              ]),
          GatewayRichTopic(
              title: 'Six Related Conditions',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'ul',
                    items: <String>[
                      'Earth',
                      'Water',
                      'Fire',
                      'Wind',
                      'Space',
                      'Time'
                    ],
                    styleClass: 'icon-list-grid'),
              ]),
          GatewayRichTopic(
              title: 'The Twelve Links of Dependent Origination',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'ol',
                    items: <String>[
                      'Ignorance',
                      'Formation',
                      'Consciousness',
                      'Name and form',
                      'The six sense sources',
                      'Contact',
                      'Sensation',
                      'Craving',
                      'Grasping',
                      'Becoming',
                      'Rebirth',
                      'Old age and death'
                    ],
                    styleClass: 'links-grid'),
              ]),
          GatewayRichTopic(
              title: 'First Subdivision of the Twelve Links',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Propelling Links',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Propelled Result',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Fully Establishing Links',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Fully Established Links',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'table',
                    headers: <String>[
                      'Propelling Links',
                      'Propelled Result',
                      'Fully Establishing Links',
                      'Fully Established Links'
                    ],
                    rows: <List<String>>[
                      <String>[
                        'Ignorance',
                        'Name and Form',
                        'Craving',
                        'Rebirth'
                      ],
                      <String>[
                        'Formation',
                        'The Six Sense Sources',
                        'Grasping',
                        'Old Age and Death'
                      ],
                      <String>[
                        'Consciousness',
                        'Contact / Sensation',
                        'Becoming'
                      ]
                    ],
                    styleClass: ''),
              ]),
          GatewayRichTopic(
              title: 'Second Subdivision of the Twelve Links',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Affliction of Disturbing Emotions',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Affliction of Karma',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Affliction of Life',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'table',
                    headers: <String>[
                      'Affliction of Disturbing Emotions',
                      'Affliction of Karma',
                      'Affliction of Life (Seven Bases of Suffering)'
                    ],
                    rows: <List<String>>[
                      <String>[
                        'Ignorance, Craving, Grasping',
                        'Formation, Becoming',
                        'Consciousness, Name and Form, Six Sense Sources, Contact, Sensation, Rebirth, Old Age and Death'
                      ]
                    ],
                    styleClass: ''),
                GatewayRichBlock(
                    type: 'p',
                    text:
                        'From the three disturbing emotions come two karmas; from these arise the seven bases of suffering.',
                    styleClass: 'callout'),
              ]),
          GatewayRichTopic(
              title: 'Third Subdivision of the Twelve Links',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Truth of Origin',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Truth of Suffering',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'table',
                    headers: <String>['Truth of Origin', 'Truth of Suffering'],
                    rows: <List<String>>[
                      <String>[
                        'Ignorance, Craving, Grasping, Formation, Becoming',
                        'Consciousness, Name and Form, Six Sense Sources, Contact, Sensation, Rebirth, Old Age and Death'
                      ]
                    ],
                    styleClass: ''),
              ]),
          GatewayRichTopic(
              title: 'Fourth Subdivision of the Twelve Links',
              blocks: <GatewayRichBlock>[
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Truth of the Path',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'chip',
                    text: 'Truth of Cessation',
                    styleClass: 'subdivision-chip'),
                GatewayRichBlock(
                    type: 'table',
                    headers: <String>[
                      'Truth of the Path (reversal)',
                      'Truth of Cessation'
                    ],
                    rows: <List<String>>[
                      <String>[
                        'Ignorance, Craving, Grasping, Formation, Becoming',
                        'Consciousness, Name and Form, Six Sense Sources, Contact, Sensation, Rebirth, Old Age and Death'
                      ]
                    ],
                    styleClass: ''),
              ]),
        ]),
  ];

  Future<GatewayRichChapter?> getChapter(int chapterNumber) async {
    for (final chapter in _chapters) {
      if (chapter.number == chapterNumber) {
        return _normalizeChapter(chapter);
      }
    }
    return null;
  }

  Future<List<GatewayOutlineChapter>> getOutlineChapters() {
    return GatewayOutlineService.instance.getChapters();
  }

  GatewayRichChapter _normalizeChapter(GatewayRichChapter chapter) {
    return GatewayRichChapter(
      number: chapter.number,
      title: chapter.title,
      topics: chapter.topics.map(_normalizeTopic).toList(),
    );
  }

  GatewayRichTopic _normalizeTopic(GatewayRichTopic topic) {
    final normalizedBlocks = <GatewayRichBlock>[];
    final blocks = topic.blocks;

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (_isInlineEnumerationParagraph(block)) {
        final run = <GatewayRichBlock>[block];
        while (i + 1 < blocks.length &&
            _isInlineEnumerationParagraph(blocks[i + 1])) {
          i += 1;
          run.add(blocks[i]);
        }
        if (run.length >= 2) {
          normalizedBlocks.add(
            GatewayRichBlock(
              type: 'ol',
              items: run.map((b) => _normalizeNumerals(b.text ?? '')).toList(),
            ),
          );
          continue;
        }
      }
      normalizedBlocks.add(_normalizeBlock(block));
    }

    return GatewayRichTopic(
      title: topic.title,
      blocks: normalizedBlocks,
    );
  }

  bool _isInlineEnumerationParagraph(GatewayRichBlock block) {
    if (block.type != 'p' || block.styleClass != 'topic-copy') return false;
    final text = block.text?.trim();
    if (text == null || text.isEmpty) return false;
    final colonIndex = text.indexOf(':');
    if (colonIndex <= 0 || colonIndex >= text.length - 1) return false;
    final body = text.substring(colonIndex + 1);
    return body.contains(',') || body.contains(';');
  }

  GatewayRichBlock _normalizeBlock(GatewayRichBlock block) {
    return GatewayRichBlock(
      type: block.type,
      text: block.text == null ? null : _normalizeNumerals(block.text!),
      items: block.items.map(_normalizeNumerals).toList(),
      headers: block.headers.map(_normalizeNumerals).toList(),
      rows: block.rows
          .map((row) => row.map(_normalizeNumerals).toList())
          .toList(),
      styleClass: block.styleClass,
    );
  }

  String _normalizeNumerals(String input) {
    return input.replaceAllMapped(RegExp(r'\b\d+\b'), (match) {
      final value = int.tryParse(match.group(0)!);
      if (value == null || value < 0 || value > 99) return match.group(0)!;

      final word = _numberToWords(value);
      if (match.start == 0 && word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      }
      return word;
    });
  }

  String _numberToWords(int value) {
    const underTwenty = <String>[
      'zero',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen',
    ];
    const tens = <String>[
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety',
    ];

    if (value < 20) return underTwenty[value];
    final tenPart = value ~/ 10;
    final onePart = value % 10;
    if (onePart == 0) return tens[tenPart];
    return '${tens[tenPart]}-${underTwenty[onePart]}';
  }
}
