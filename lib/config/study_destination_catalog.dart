import 'study_text_config.dart';

/// Unified destination metadata used by landing, mobile home/onboarding,
/// settings, and daily-notification eligibility.
class StudyDestination {
  const StudyDestination({
    required this.id,
    required this.title,
    required this.author,
    required this.path,
    required this.supportsDaily,
    required this.supportsOptionsScreen,
    this.textId,
  });

  /// Stable identifier persisted in preferences.
  final String id;

  final String title;
  final String author;
  final String path;

  /// Backing text id for study-text destinations; null for gateway.
  final String? textId;

  /// True when this destination can produce a daily verse.
  final bool supportsDaily;

  /// True when opening this destination goes to [TextOptionsScreen].
  final bool supportsOptionsScreen;

  bool get isGateway => textId == null;
}

const String gatewayDestinationId = 'gateway_to_knowledge';

List<StudyDestination> getStudyDestinations() {
  final destinations = <StudyDestination>[
    const StudyDestination(
      id: gatewayDestinationId,
      title: 'Gateway to Knowledge',
      author: 'JAMGON JU MIPHAM',
      path: '/gateway-to-knowledge',
      textId: null,
      supportsDaily: false,
      supportsOptionsScreen: false,
    ),
  ];

  for (final text in studyTextRegistry.where((c) => c.hasCoreStudySupport)) {
    destinations.add(StudyDestination(
      id: text.textId,
      title: text.title,
      author: text.author,
      path: text.path,
      textId: text.textId,
      supportsDaily: text.supportsMode('daily'),
      supportsOptionsScreen: true,
    ));
  }

  return destinations;
}

StudyDestination? getStudyDestinationById(String id) {
  final normalized = id.trim();
  if (normalized.isEmpty) return null;
  for (final destination in getStudyDestinations()) {
    if (destination.id == normalized) return destination;
  }
  return null;
}

List<StudyDestination> getSelectedDestinations(Set<String> selectedIds) {
  if (selectedIds.isEmpty) return const <StudyDestination>[];
  final selected = <StudyDestination>[];
  for (final destination in getStudyDestinations()) {
    if (selectedIds.contains(destination.id)) {
      selected.add(destination);
    }
  }
  return selected;
}

List<StudyDestination> getDailyEligibleDestinations(Set<String> selectedIds) {
  return getSelectedDestinations(selectedIds)
      .where((destination) => destination.supportsDaily)
      .toList();
}

Set<String> allStudyDestinationIds() {
  return getStudyDestinations().map((destination) => destination.id).toSet();
}
