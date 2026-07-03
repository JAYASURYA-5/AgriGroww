class SchemeItem {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int launchYear;
  final String financialSupport;
  final String productivityImprovement;
  final String riskProtection;
  final String trainingAwareness;
  final String infrastructureSupport;
  final String marketSupport;
  final String weatherAdvisory;
  final String source;
  final String? link;
  final String category;
  final bool priority;

  SchemeItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.launchYear,
    required this.financialSupport,
    required this.productivityImprovement,
    required this.riskProtection,
    required this.trainingAwareness,
    required this.infrastructureSupport,
    required this.marketSupport,
    required this.weatherAdvisory,
    required this.source,
    this.link,
    required this.category,
    this.priority = false,
  });
}
