import 'package:flutter/foundation.dart';

import '../models/citizen_profile.dart';
import '../models/civic_report.dart';
import '../models/report_draft.dart';

abstract interface class ReportsRepository {
  ValueListenable<List<CivicReport>> get reports;

  Stream<List<CivicReport>> watchReports();
  Stream<CivicReport?> watchReport(String id);
  Future<List<CivicReport>> listReports();
  Future<CivicReport?> getReport(String id);
  Future<CivicReport> createReport(ReportDraft draft);
  Future<CivicReport?> updateReport(String id, CivicReport updatedReport);
  Future<CivicReport?> updateReportStatus(String id, ReportStatus status);
  Future<bool> deleteReport(String id);
}

abstract interface class ProfileRepository {
  ValueListenable<CitizenProfile> get profile;

  Stream<CitizenProfile> watchProfile();
  Future<CitizenProfile> readProfile();
  Future<CitizenProfile> createProfile(CitizenProfile newProfile);
  Future<CitizenProfile> updateProfile(CitizenProfile updatedProfile);
  Future<CitizenProfile> updateTwoStep(bool enabled);
  Future<void> deleteProfile();
}
