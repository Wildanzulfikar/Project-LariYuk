import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user is logged in');
    return user.uid;
  }

  Future<void> createUserDocument() async {
    try {
      final userId = _currentUserId;
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user is logged in');
      final userDoc = await _db.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        await _db.collection('users').doc(userId).set({
          'email': user.email ?? 'user@example.com',
          'name': user.displayName ?? 'Unknown User',
          'avatarUrl':
              user.photoURL ?? 'https://example.com/default-avatar.jpg',
          'birthdate': Timestamp.fromDate(DateTime(2004, 1, 1)),
          'gender': 'male',
          'height': 175,
          'weight': 65,
          'level': 1,
          'points': 0,
          'totalRuns': 0,
          'totalDistance': 0.0,
          'is_new': true,
          'createdAt': Timestamp.now(),
        });

        print('New user document created for ${user.email}');
      } else {
        print('User document already exists for ${user.email}');
      }
    } catch (e) {
      print('Error creating user document: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> getTodayRunningData() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('No user logged in');

      final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // WIB
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      print('Query range: $startOfDay to $endOfDay');
      final querySnapshot =
          await _db
              .collection('users')
              .doc(userId)
              .collection('running_history')
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
              .get();

      print('Fetched runs: ${querySnapshot.docs.length}');
      if (querySnapshot.docs.isNotEmpty) {
        final runData = querySnapshot.docs.first.data();
        print('Run data: $runData');
        return {
          'calories': runData['calories'] ?? 0,
          'steps': runData['steps'] ?? 0,
          'distance': runData['distance'] ?? 0.0,
          'duration': runData['duration'] ?? 0.0,
        };
      } else {
        print('No runs found for today');
        return null;
      }
    } catch (e) {
      print('Error fetching today\'s running data: $e');
      throw e;
    }
  }

  Future<void> initializeDatabaseStructure() async {
    await createUserDocument();
  }
}