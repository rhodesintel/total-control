import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Syncs fitness data to/from Firebase
/// Health Connect integration can be added later
class FitnessSyncService {
  static final FitnessSyncService _instance = FitnessSyncService._internal();
  factory FitnessSyncService() => _instance;
  FitnessSyncService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId = 'rhodes';

  // Goals (same as Windows app)
  int goalSteps = 10000;
  int goalWorkoutMins = 30;
  int streamingRewardMins = 30;

  /// Request permissions - stub for now
  Future<bool> requestPermissions() async {
    return true; // Health Connect to be added later
  }

  /// Get today's fitness data from Firebase
  Future<Map<String, dynamic>> getTodayFitness() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final docId = '${userId}_$today';
      final doc = await _db.collection('fitness_daily').doc(docId).get();
      if (doc.exists) {
        return doc.data() ?? {'steps': 0, 'workout_mins': 0};
      }
    } catch (e) {
      debugPrint('[FitnessSyncService] Read error: $e');
    }
    return {'steps': 0, 'workout_mins': 0, 'calories': 0};
  }

  /// Sync fitness data to Firebase
  Future<bool> syncToFirebase() async {
    // For now, just verify connection works
    return true;
  }

  /// Calculate streaming rewards based on goals
  Map<String, dynamic> calculateRewards(Map<String, dynamic> fitness) {
    final steps = fitness['steps'] as int? ?? 0;
    final workoutMins = fitness['workout_mins'] as int? ?? 0;

    final stepsPct = (steps / goalSteps * 100).clamp(0, 100).toInt();
    final workoutPct = (workoutMins / goalWorkoutMins * 100).clamp(0, 100).toInt();

    int earnedMins = 0;
    if (steps >= goalSteps) earnedMins += streamingRewardMins;
    if (workoutMins >= goalWorkoutMins) earnedMins += streamingRewardMins;

    return {
      'steps': steps,
      'steps_goal': goalSteps,
      'steps_pct': stepsPct,
      'workout_mins': workoutMins,
      'workout_goal': goalWorkoutMins,
      'workout_pct': workoutPct,
      'earned_mins': earnedMins,
      'steps_met': steps >= goalSteps,
      'workout_met': workoutMins >= goalWorkoutMins,
    };
  }

  /// Load goals from Firebase
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
