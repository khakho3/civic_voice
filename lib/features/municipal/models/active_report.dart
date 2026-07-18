/// Status-based filter chips for MUN-006 — a strict subset of [ReportStatus]:
/// only statuses relevant once a report has moved past triage into active
/// maintenance work.
enum ActiveReportFilter {
  all('All'),
  assigned('Assigned'),
  inProgress('In Progress'),
  resolved('Resolved');

  const ActiveReportFilter(this.label);

  final String label;
}

enum ActiveReportSort {
  mostRecent('Most Recent'),
  highestProgress('Highest Progress'),
  lowestProgress('Lowest Progress');

  const ActiveReportSort(this.label);

  final String label;
}
