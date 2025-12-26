import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Syncs fitness data from Health Connect to Firebase
/// STUB VERSION - Health package disabled for CI build
class FitnessSyncService {
  static final FitnessSyncService _instance = FitnessSyncService._internal();
  factory FitnessSyncService() => _instance;
  FitnessSyncService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId = 'rhodes';

  int goalSteps = 10000;
  int goalWorkoutMins = 30;
  int streamingRewardMins = 30;

  Future<bool> requestPermissions() async {
    debugPrint('[FitnessSyncService] Health package disabled - using Firebase data only');
    return false;
  }

  Future<Map<String, dynamic>> getTodayFitness() async {
    final fbData = await getFromFirebase();
    if (fbData != null) {
      return {
        'steps': fbData['steps'] ?? 0,
        'workout_mins': fbData['workout_mins'] ?? 0,
        'calories': fbData['calories'] ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    return {'steps': 0, 'workout_mins': 0, 'calories': 0, 'timestamp': DateTime.now().toIso8601String()};
  }

  Future<bool> syncToFirebase() async {
    try {
      final fitness = await getTodayFitness();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final docId = '${userId}_$today';
      await _db.collection('fitness_daily').doc(docId).set({
        ...fitness, 'user_id': userId, 'date': today, 'synced_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FitnessSyncService] Synced to Firebase: $docId');
      return true;
    } catch (e) {
      debugPrint('[FitnessSyncService] Sync error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getFromFirebase() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final docId = '${userId}_$today';
      final doc = await _db.collection('fitness_daily').doc(docId).get();
      return doc.data();
    } catch (e) {
      debugPrint('[FitnessSyncService] Firebase read error: $e');
      return null;
    }
  }

  Map<String, dynamic> calculateRewards(Map<String, dynamic> fitness) {
    final steps = fitness['steps'] as int? ?? 0;
    final workoutMins = fitness['workout_mins'] as int? ?? 0;
    final stepsPct = (steps / goalSteps * 100).clamp(0, 100).toInt();
    final workoutPct = (workoutMins / goalWorkoutMins * 100).clamp(0, 100).toInt();
    int earnedMins = 0;
    if (steps >= goalSteps) earnedMins += streamingRewardMins;
    if (workoutMins >= goalWorkoutMins) earnedMins += streamingRewardMins;
    return {
      'steps': steps, 'steps_goal': goalSteps, 'steps_pct': stepsPct,
      'workout_mins': workoutMins, 'workout_goal': goalWorkoutMins, 'workout_pct': workoutPct,
      'earned_mins': earnedMins, 'steps_met': steps >= goalSteps, 'workout_met': workoutMins >= goalWorkoutMins,
    };
  }

  Future<void> loadGoals() async {
    try {
      final doc = await _db.collection('goals').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        goalSteps = data['daily_steps'] as int? ?? 10000;
        goalWorkoutMins = data['daily_workout_mins'] as int? ?? 30;
        streamingRewardMins = data['streaming_reward_mins'] as int? ?? 30;
      }
    } catch (e) {
      debugPrint('[FitnessSyncService] Goals load error: $e');
    }
  }
}
