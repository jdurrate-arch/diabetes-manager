// ============================================================
// MODELS - All data models for the diabetes management app
// ============================================================

class FoodEntry {
  final int? id;
  final String date; // yyyy-MM-dd
  final String mealType; // breakfast, lunch, dinner, snack
  final String foodDescription;
  final double? calories;
  final double? carbs;
  final double? glucoseBefore;
  final double? glucoseAfter;
  final String? notes;
  final DateTime createdAt;

  FoodEntry({
    this.id,
    required this.date,
    required this.mealType,
    required this.foodDescription,
    this.calories,
    this.carbs,
    this.glucoseBefore,
    this.glucoseAfter,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'meal_type': mealType,
    'food_description': foodDescription,
    'calories': calories,
    'carbs': carbs,
    'glucose_before': glucoseBefore,
    'glucose_after': glucoseAfter,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory FoodEntry.fromMap(Map<String, dynamic> map) => FoodEntry(
    id: map['id'],
    date: map['date'],
    mealType: map['meal_type'],
    foodDescription: map['food_description'],
    calories: map['calories']?.toDouble(),
    carbs: map['carbs']?.toDouble(),
    glucoseBefore: map['glucose_before']?.toDouble(),
    glucoseAfter: map['glucose_after']?.toDouble(),
    notes: map['notes'],
    createdAt: DateTime.parse(map['created_at']),
  );

  FoodEntry copyWith({
    int? id,
    String? date,
    String? mealType,
    String? foodDescription,
    double? calories,
    double? carbs,
    double? glucoseBefore,
    double? glucoseAfter,
    String? notes,
  }) => FoodEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    mealType: mealType ?? this.mealType,
    foodDescription: foodDescription ?? this.foodDescription,
    calories: calories ?? this.calories,
    carbs: carbs ?? this.carbs,
    glucoseBefore: glucoseBefore ?? this.glucoseBefore,
    glucoseAfter: glucoseAfter ?? this.glucoseAfter,
    notes: notes ?? this.notes,
    createdAt: createdAt,
  );
}

// ────────────────────────────────────────────────────────────

class VitalsEntry {
  final int? id;
  final String date;
  final double? weight;       // kg
  final double? height;       // cm
  final int? systolic;        // mmHg
  final int? diastolic;       // mmHg
  final int? heartRate;       // bpm
  final DateTime createdAt;

  VitalsEntry({
    this.id,
    required this.date,
    this.weight,
    this.height,
    this.systolic,
    this.diastolic,
    this.heartRate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double? get bmi {
    if (weight == null || height == null || height! <= 0) return null;
    final heightM = height! / 100;
    return weight! / (heightM * heightM);
  }

  String get bmiCategory {
    final b = bmi;
    if (b == null) return 'N/A';
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'weight': weight,
    'height': height,
    'systolic': systolic,
    'diastolic': diastolic,
    'heart_rate': heartRate,
    'created_at': createdAt.toIso8601String(),
  };

  factory VitalsEntry.fromMap(Map<String, dynamic> map) => VitalsEntry(
    id: map['id'],
    date: map['date'],
    weight: map['weight']?.toDouble(),
    height: map['height']?.toDouble(),
    systolic: map['systolic'],
    diastolic: map['diastolic'],
    heartRate: map['heart_rate'],
    createdAt: DateTime.parse(map['created_at']),
  );

  VitalsEntry copyWith({
    int? id,
    String? date,
    double? weight,
    double? height,
    int? systolic,
    int? diastolic,
    int? heartRate,
  }) => VitalsEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    weight: weight ?? this.weight,
    height: height ?? this.height,
    systolic: systolic ?? this.systolic,
    diastolic: diastolic ?? this.diastolic,
    heartRate: heartRate ?? this.heartRate,
    createdAt: createdAt,
  );
}

// ────────────────────────────────────────────────────────────

class ActivityEntry {
  final int? id;
  final String date;
  final String? sleepTime;        // HH:mm
  final String? wakeTime;         // HH:mm
  final int? walkingMinutes;
  final int? exerciseMinutes;
  final double? screenTimeHours;
  final double? drivingHours;
  final String? activityNotes;
  final DateTime createdAt;

  ActivityEntry({
    this.id,
    required this.date,
    this.sleepTime,
    this.wakeTime,
    this.walkingMinutes,
    this.exerciseMinutes,
    this.screenTimeHours,
    this.drivingHours,
    this.activityNotes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalSleepHours {
    if (sleepTime == null || wakeTime == null) return 0;
    try {
      final sleepParts = sleepTime!.split(':');
      final wakeParts = wakeTime!.split(':');
      final sleepMinutes = int.parse(sleepParts[0]) * 60 + int.parse(sleepParts[1]);
      var wakeMinutes = int.parse(wakeParts[0]) * 60 + int.parse(wakeParts[1]);
      if (wakeMinutes < sleepMinutes) wakeMinutes += 24 * 60;
      return (wakeMinutes - sleepMinutes) / 60.0;
    } catch (_) {
      return 0;
    }
  }

  int get totalActiveMinutes => (walkingMinutes ?? 0) + (exerciseMinutes ?? 0);

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'sleep_time': sleepTime,
    'wake_time': wakeTime,
    'walking_minutes': walkingMinutes,
    'exercise_minutes': exerciseMinutes,
    'screen_time_hours': screenTimeHours,
    'driving_hours': drivingHours,
    'activity_notes': activityNotes,
    'created_at': createdAt.toIso8601String(),
  };

  factory ActivityEntry.fromMap(Map<String, dynamic> map) => ActivityEntry(
    id: map['id'],
    date: map['date'],
    sleepTime: map['sleep_time'],
    wakeTime: map['wake_time'],
    walkingMinutes: map['walking_minutes'],
    exerciseMinutes: map['exercise_minutes'],
    screenTimeHours: map['screen_time_hours']?.toDouble(),
    drivingHours: map['driving_hours']?.toDouble(),
    activityNotes: map['activity_notes'],
    createdAt: DateTime.parse(map['created_at']),
  );

  ActivityEntry copyWith({
    int? id,
    String? date,
    String? sleepTime,
    String? wakeTime,
    int? walkingMinutes,
    int? exerciseMinutes,
    double? screenTimeHours,
    double? drivingHours,
    String? activityNotes,
  }) => ActivityEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    sleepTime: sleepTime ?? this.sleepTime,
    wakeTime: wakeTime ?? this.wakeTime,
    walkingMinutes: walkingMinutes ?? this.walkingMinutes,
    exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
    screenTimeHours: screenTimeHours ?? this.screenTimeHours,
    drivingHours: drivingHours ?? this.drivingHours,
    activityNotes: activityNotes ?? this.activityNotes,
    createdAt: createdAt,
  );
}

// ────────────────────────────────────────────────────────────

class NotificationSetting {
  final int? id;
  final String type;         // bedtime, medicine, insulin, custom
  final String title;
  final String body;
  final String time;         // HH:mm
  final bool isEnabled;
  final List<int> days;      // 1=Mon..7=Sun (empty = daily)

  NotificationSetting({
    this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isEnabled = true,
    this.days = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'time': time,
    'is_enabled': isEnabled ? 1 : 0,
    'days': days.join(','),
  };

  factory NotificationSetting.fromMap(Map<String, dynamic> map) => NotificationSetting(
    id: map['id'],
    type: map['type'],
    title: map['title'],
    body: map['body'],
    time: map['time'],
    isEnabled: map['is_enabled'] == 1,
    days: map['days'] != null && (map['days'] as String).isNotEmpty
        ? (map['days'] as String).split(',').map(int.parse).toList()
        : [],
  );

  NotificationSetting copyWith({
    int? id,
    String? type,
    String? title,
    String? body,
    String? time,
    bool? isEnabled,
    List<int>? days,
  }) => NotificationSetting(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    time: time ?? this.time,
    isEnabled: isEnabled ?? this.isEnabled,
    days: days ?? this.days,
  );
}

// ────────────────────────────────────────────────────────────

class DailySummary {
  final String date;
  final List<FoodEntry> foodEntries;
  final VitalsEntry? vitals;
  final ActivityEntry? activity;

  DailySummary({
    required this.date,
    required this.foodEntries,
    this.vitals,
    this.activity,
  });

  double get avgGlucoseBefore {
    final readings = foodEntries
        .where((e) => e.glucoseBefore != null)
        .map((e) => e.glucoseBefore!)
        .toList();
    if (readings.isEmpty) return 0;
    return readings.reduce((a, b) => a + b) / readings.length;
  }

  double get avgGlucoseAfter {
    final readings = foodEntries
        .where((e) => e.glucoseAfter != null)
        .map((e) => e.glucoseAfter!)
        .toList();
    if (readings.isEmpty) return 0;
    return readings.reduce((a, b) => a + b) / readings.length;
  }

  double get maxGlucose {
    final allGlucose = [
      ...foodEntries.where((e) => e.glucoseBefore != null).map((e) => e.glucoseBefore!),
      ...foodEntries.where((e) => e.glucoseAfter != null).map((e) => e.glucoseAfter!),
    ];
    if (allGlucose.isEmpty) return 0;
    return allGlucose.reduce((a, b) => a > b ? a : b);
  }

  bool get isGlucoseControlled {
    if (foodEntries.isEmpty) return false;
    final avg = (avgGlucoseBefore + avgGlucoseAfter) / 2;
    return avg > 0 && avg <= 140;
  }
}
