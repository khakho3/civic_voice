/// Shared report-category model.
///
/// Originally Municipal-only (Infrastructure/Safety/Sanitation), promoted
/// here so Citizen's auto-classifier can target the same categories
/// municipal staff already triage by — one taxonomy, not two competing
/// ones. [other] is the classifier's fallback bucket for reports that
/// don't clearly match any category's keywords, not a value a citizen
/// picks directly.
enum ReportCategory {
  infrastructure('Infrastructure'),
  safety('Safety'),
  sanitation('Sanitation'),
  other('Other');

  const ReportCategory(this.label);

  final String label;
}
