import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bug_report_model.dart';
import '../core/constants.dart';

class BugReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> submitBugReport(BugReportModel report) async {
    await _firestore
        .collection(AppConstants.bugReportsCollection)
        .add(report.toFirestore());
  }
  
  Stream<List<BugReportModel>> getUserBugReports(String userId) {
    return _firestore
        .collection(AppConstants.bugReportsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BugReportModel.fromFirestore(doc))
            .toList());
  }
}
