import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

/// Syncs fitness data from Health Connect to Firebase
/// Same Firestore structure as Windows app (fitness_daily collection)
class FitnessSyncService {
  static final FitnessSyncService _instance = FitnessSyncService._internal();
  factory FitnessSyncService() => _instance;
  FitnessSyncService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Health _health = Health();
  final String userId = 'rhodes';

  // Goals (same as Windows app)
  int goalSteps = 10000;
  int goalWorkoutMins = 30;
  int streamingRewardMins = 30; // Reward per goal met

  bool _isAuthorized = false;

  /// Request Health Connect permissions
  Future<bool> requestPermissions() async {
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.WORKOUT,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];

      final permissions = types.map((e) => HealthDataAccess.READ).toList();

      _isAuthorized = await _health.requestAuthorization(types, permissions: permissions);
      debugPrint('[FitnessSyncService] Authorization: $_isAuthorized');
      return _isAuthorized;
    } catch (e) {
      debugPrint('[FitnessSyncService] Auth error: $e');
      return false;
    }
  }

  /// Get today's fitness data from Health Connect
  Future<Map<String, dynamic>> getTodayFitness() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    int steps = 0;
    int workoutMins = 0;
    int calories = 0;

    try {
      // Get steps
      final stepsData = await _health.getTotalStepsInInterval(startOfDay, now);
      steps = stepsData ?? 0;

      // Get workouts and calories (v10.x uses positional params)
      final healthData = await _health.getHealthDataFromTypes(
        startOfDay,
        now,
        [HealthDataType.WORKOUT, HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      for (final point in healthData) {
        if (point.type == HealthDataType.WORKOUT) {
          // Calculate workout duration in minutes
          final duration = point.dateTo.difference(point.dateFrom);
          workoutMins += duration.inMinutes;
        } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          calories += (point.value as NumericHealthValue).numericValue.toInt();
        }
      }
    } catch (e) {
      debugPrint('[FitnessSyncService] Read error: $e');
    }

    return {
      'steps': steps,
      'workout_mins': workoutMins,
      'calories': calories,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Sync fitness data to Firebase (same structure as Windows app)
  Future<bool> syncToFirebase() async {
    try {
      final fitness = await getTodayFitness();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final docId = '${userId}_$today';

      await _db.collection('fitness_daily').doc(docId).set({
        ...fitness,
        'user_id': userId,
        'date': today,
        'synced_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[FitnessSyncService] Synced to Firebase: $docId');
      return true;
    } catch (e) {
      debugPrint('[FitnessSyncService] Sync error: $e');
      return false;
    }
  }

  /// Get today's data from Firebase (in case Windows app updated it)
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

  /// Calculate streaming rewards based on goals
  /// Returns minutes of streaming earned
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
