List<String> experienceMetadataValues(Map<String, dynamic> experience) {
  String valueOf(String key) {
    final value = experience[key];
    return value is String ? value.trim() : '';
  }

  final subject = valueOf('subject').isNotEmpty
      ? valueOf('subject')
      : valueOf('category');
  final indoorOutdoor = valueOf('indoorOutdoor').isNotEmpty
      ? valueOf('indoorOutdoor')
      : valueOf('environment');
  final guidance = valueOf('guidanceType').isNotEmpty
      ? valueOf('guidanceType')
      : valueOf('type');

  return [
    subject,
    indoorOutdoor,
    guidance,
  ].where((value) => value.isNotEmpty).toList();
}

String experienceMetadata(Map<String, dynamic> experience) =>
    experienceMetadataValues(experience).join(' · ');
