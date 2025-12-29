/// TotalControl Rule Model
/// "NO X UNTIL X" - Simple rule-based blocking

enum ConditionType {
  steps,      // NO X UNTIL 10,000 steps
  time,       // NO X UNTIL 5:00 PM
  workout,    // NO X UNTIL 30min workout
  location,   // NO X UNTIL at gym
  tomorrow,   // NO X UNTIL tomorrow
  password,   // NO X UNTIL password entered
}

class Location {
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'lat': latitude,
    'lng': longitude,
    'radius': radiusMeters,
  };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    name: json['name'],
    latitude: json['lat'],
    longitude: json['lng'],
    radiusMeters: json['radius'] ?? 100,
  );
}

class Condition {
  final ConditionType type;
  final int? stepsTarget;
  final String? timeTarget; // "17:00"
  final int? workoutMinutes;
  final Location? location;

  Condition({
    required this.type,
    this.stepsTarget,
    this.timeTarget,
    this.workoutMinutes,
    this.location,
  });

  String describe() {
    switch (type) {
      case ConditionType.steps:
        return '${stepsTarget?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} steps';
      case ConditionType.time:
        return timeTarget ?? 'time';
      case ConditionType.workout:
        return '${workoutMinutes}min workout';
      case ConditionType.location:
        return 'at ${location?.name ?? "location"}';
      case ConditionType.tomorrow:
        return 'tomorrow';
      case ConditionType.password:
        return 'password';
    }
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type.name};
    if (stepsTarget != null) json['steps_target'] = stepsTarget;
    if (timeTarget != null) json['time_target'] = timeTarget;
    if (workoutMinutes != null) json['workout_minutes'] = workoutMinutes;
    if (location != null) json['location'] = location!.toJson();
    return json;
  }

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      type: ConditionType.values.firstWhere((e) => e.name == json['type']),
      stepsTarget: json['steps_target'],
      timeTarget: json['time_target'],
      workoutMinutes: json['workout_minutes'],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
    );
  }
}

class Rule {
  final String id;
  final List<String> blockedItems;
  final Condition condition;
  final bool enabled;
  final DateTime createdAt;

  Rule({
    required this.id,
    required this.blockedItems,
    required this.condition,
    this.enabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String describe() {
    final items = blockedItems.take(3).join(', ');
    final suffix = blockedItems.length > 3 ? ' +${blockedItems.length - 3}' : '';
    return 'NO $items$suffix UNTIL ${condition.describe()}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'blocked_items': blockedItems,
    'condition': condition.toJson(),
    'enabled': enabled,
    'created_at': createdAt.toIso8601String(),
  };

  factory Rule.fromJson(Map<String, dynamic> json) => Rule(
    id: json['id'],
    blockedItems: List<String>.from(json['blocked_items']),
    condition: Condition.fromJson(json['condition']),
    enabled: json['enabled'] ?? true,
    createdAt: DateTime.tryParse(json['created_at'] ?? ''),
  );
}

class Progress {
  int stepsToday;
  int workoutMinutesToday;
  Location? currentLocation;

  Progress({
    this.stepsToday = 0,
    this.workoutMinutesToday = 0,
    this.currentLocation,
  });

  (bool met, String status) checkCondition(Condition condition) {
    switch (condition.type) {
      case ConditionType.steps:
        final target = condition.stepsTarget ?? 10000;
        final met = stepsToday >= target;
        final pct = (stepsToday / target * 100).clamp(0, 100).toInt();
        return (met, '$stepsToday/$target ($pct%)');

      case ConditionType.time:
        final parts = (condition.timeTarget ?? '17:00').split(':');
        final targetHour = int.parse(parts[0]);
        final targetMin = parts.length > 1 ? int.parse(parts[1]) : 0;
        final now = DateTime.now();
        final target = DateTime(now.year, now.month, now.day, targetHour, targetMin);

        if (now.isAfter(target)) {
          return (true, 'Time reached');
        }
        final diff = target.difference(now);
        if (diff.inMinutes > 60) {
          return (false, '${diff.inHours}h ${diff.inMinutes % 60}m left');
        }
        return (false, '${diff.inMinutes}m left');

      case ConditionType.workout:
        final target = condition.workoutMinutes ?? 30;
        final met = workoutMinutesToday >= target;
        return (met, '$workoutMinutesToday/${target}min');

      case ConditionType.location:
        if (currentLocation == null || condition.location == null) {
          return (false, 'Location unknown');
        }
        // Simple distance check
        final dx = currentLocation!.latitude - condition.location!.latitude;
        final dy = currentLocation!.longitude - condition.location!.longitude;
        final distMeters = (dx * dx + dy * dy) * 111000; // rough
        final met = distMeters <= condition.location!.radiusMeters;
        return (met, met ? 'At ${condition.location!.name}' : 'Not at ${condition.location!.name}');

      case ConditionType.tomorrow:
        return (false, 'Blocked until tomorrow');

      case ConditionType.password:
        return (false, 'Enter password');
    }
  }
}
