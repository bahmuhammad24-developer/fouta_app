/// Simple client-side queries for creator dashboards.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_paths.dart';

class CreatorInsights {
  CreatorInsights({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<int> countPostsLastNDays(String uid, int n) async {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(Duration(days: n)));
    final snap = await _firestore
        .collection(FirestorePaths.posts())
        .where('authorId', isEqualTo: uid)
        .where('timestamp', isGreaterThan: cutoff)
        .get();
    return snap.size;
  }

  Future<int> sumEngagementLastNDays(String uid, int n) async {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(Duration(days: n)));
    final snap = await _firestore
        .collection(FirestorePaths.posts())
        .where('authorId', isEqualTo: uid)
        .where('timestamp', isGreaterThan: cutoff)
        .get();
    var total = 0;
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['likeIds'] as List?)?.length ?? 0;
    }
    return total;
  }
}
