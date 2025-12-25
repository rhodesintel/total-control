enum GoalType {
  realtime, // Can check progress now (steps, bank balance)
  delayed,  // Result comes later (exam scores, applications)
}

enum GoalStatus {
  active,   // In progress
  waiting,  // Delayed type - awaiting result
  achieved, // Goal met
  failed,   // Goal missed
}

class Goal {
  final String id;
  final String name;
  final GoalType type;
  final double target;
  final double? current;
  final String unit;
  final DateTime deadline;
  final List<String> rewardApps; // Apps/sites to unlock on success
  final String source; // Where to check (Google Fit, Plaid, LSAC, etc)
  final GoalStatus status;

  // For delayed goals
  final bool gracePeriod; // Unlock during wait?
  final bool resultArrived;
  final DateTime? nextAttemptDate;

  Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    this.current,
    required this.unit,
    required this.deadline,
    required this.rewardApps,
    required this.source,
    required this.status,
    this.gracePeriod = false,
    this.resultArrived = false,
    this.nextAttemptDate,
  });

  double get progress => current != null ? (current! / target).clamp(0.0, 1.0) : 0.0;
  bool get isMet => current != null && current! >= target;
  double get remaining => current != null ? (target - current!).clamp(0, double.infinity) : target;

  Goal copyWith({
    String? id,
    String? name,
    GoalType? type,
    double? target,
    double? current,
    String? unit,
    DateTime? deadline,
    List<String>? rewardApps,
    String? source,
    GoalStatus? status,
    bool? gracePeriod,
    bool? resultArrived,
    DateTime? nextAttemptDate,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      target: target ?? this.target,
      current: current ?? this.current,
      unit: unit ?? this.unit,
      deadline: deadline ?? this.deadline,
      rewardApps: rewardApps ?? this.rewardApps,
      source: source ?? this.source,
      status: status ?? this.status,
      gracePeriod: gracePeriod ?? this.gracePeriod,
      resultArrived: resultArrived ?? this.resultArrived,
      nextAttemptDate: nextAttemptDate ?? this.nextAttemptDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'target': target,
    'current': current,
    'unit': unit,
    'deadline': deadline.toIso8601String(),
    'rewardApps': rewardApps,
    'source': source,
    'status': status.name,
    'gracePeriod': gracePeriod,
    'resultArrived': resultArrived,
    'nextAttemptDate': nextAttemptDate?.toIso8601String(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'],
    name: json['name'],
    type: GoalType.values.byName(json['type']),
    target: json['target'].toDouble(),
    current: json['current']?.toDouble(),
    unit: json['unit'],
    deadline: DateTime.parse(json['deadline']),
    rewardApps: List<String>.from(json['rewardApps']),
    source: json['source'],
    status: GoalStatus.values.byName(json['status']),
    gracePeriod: json['gracePeriod'] ?? false,
    resultArrived: json['resultArrived'] ?? false,
    nextAttemptDate: json['nextAttemptDate'] != null
        ? DateTime.parse(json['nextAttemptDate'])
        : null,
  );
}
