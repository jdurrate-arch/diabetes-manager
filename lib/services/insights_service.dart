import '../models/models.dart';

class InsightsService {
  static final InsightsService _instance = InsightsService._internal();
  factory InsightsService() => _instance;
  InsightsService._internal();

  /// Analyzes controlled-glucose days and finds patterns
  List<String> generateInsights(List<DailySummary> summaries) {
    if (summaries.isEmpty) return [_noDataInsight()];

    final insights = <String>[];
    final controlled = summaries.where((s) => s.isGlucoseControlled).toList();
    final uncontrolled = summaries.where((s) => !s.isGlucoseControlled && s.avgGlucoseBefore > 0).toList();

    if (controlled.isEmpty) {
      insights.add('📊 No well-controlled glucose days found yet. Keep logging consistently for personalized insights.');
      insights.addAll(_generalTips());
      return insights;
    }

    // Walking analysis
    final controlledWalking = controlled
        .where((s) => s.activity?.walkingMinutes != null)
        .map((s) => s.activity!.walkingMinutes!.toDouble())
        .toList();
    final uncontrolledWalking = uncontrolled
        .where((s) => s.activity?.walkingMinutes != null)
        .map((s) => s.activity!.walkingMinutes!.toDouble())
        .toList();

    if (controlledWalking.isNotEmpty) {
      final avgControlledWalk = _avg(controlledWalking);
      final avgUncontrolledWalk = uncontrolledWalking.isNotEmpty ? _avg(uncontrolledWalking) : 0.0;

      if (avgControlledWalk >= 20) {
        insights.add(
          '🚶 Walking correlation: On your best glucose days, you walked an average of '
          '${avgControlledWalk.toStringAsFixed(0)} min/day'
          '${avgUncontrolledWalk > 0 ? " vs. ${avgUncontrolledWalk.toStringAsFixed(0)} min on higher-glucose days" : ""}. '
          'Aim for at least 30 minutes of walking daily to maintain this benefit.',
        );
      }
      if (avgControlledWalk > avgUncontrolledWalk + 10) {
        insights.add(
          '✅ Key finding: Walking ${(avgControlledWalk - avgUncontrolledWalk).toStringAsFixed(0)} more minutes per day '
          'appears strongly correlated with better blood sugar control for you.',
        );
      }
    }

    // Screen time analysis
    final controlledScreen = controlled
        .where((s) => s.activity?.screenTimeHours != null)
        .map((s) => s.activity!.screenTimeHours!)
        .toList();
    final uncontrolledScreen = uncontrolled
        .where((s) => s.activity?.screenTimeHours != null)
        .map((s) => s.activity!.screenTimeHours!)
        .toList();

    if (controlledScreen.isNotEmpty && uncontrolledScreen.isNotEmpty) {
      final avgControlledScreen = _avg(controlledScreen);
      final avgUncontrolledScreen = _avg(uncontrolledScreen);
      if (avgUncontrolledScreen - avgControlledScreen >= 1.5) {
        insights.add(
          '💻 Screen time alert: On poorly-controlled days, you averaged '
          '${avgUncontrolledScreen.toStringAsFixed(1)} hrs of screen time vs. '
          '${avgControlledScreen.toStringAsFixed(1)} hrs on controlled days. '
          'Prolonged sedentary screen time raises insulin resistance. Take a 5-minute walk every hour.',
        );
      }
    }

    // Sleep analysis
    final controlledSleep = controlled
        .where((s) => s.activity != null && s.activity!.totalSleepHours > 0)
        .map((s) => s.activity!.totalSleepHours)
        .toList();

    if (controlledSleep.isNotEmpty) {
      final avgSleep = _avg(controlledSleep);
      if (avgSleep >= 7 && avgSleep <= 9) {
        insights.add(
          '😴 Sleep is your ally: Your glucose was well-controlled on days you slept '
          '~${avgSleep.toStringAsFixed(1)} hours. Maintain a consistent sleep schedule between 7–9 hours.',
        );
      } else if (avgSleep < 7) {
        insights.add(
          '⚠️ Sleep deficit noticed: Even on your better days, you averaged only '
          '${avgSleep.toStringAsFixed(1)} hrs of sleep. Poor sleep raises cortisol and blood sugar. '
          'Target 7–9 hours nightly.',
        );
      }
    }

    // Food correlation analysis
    final allFoods = controlled
        .expand((s) => s.foodEntries)
        .map((e) => e.foodDescription.toLowerCase())
        .toList();

    final foodFrequency = <String, int>{};
    for (final food in allFoods) {
      final words = food.split(RegExp(r'[\s,]+'));
      for (final word in words) {
        if (word.length > 3) {
          foodFrequency[word] = (foodFrequency[word] ?? 0) + 1;
        }
      }
    }

    if (foodFrequency.isNotEmpty) {
      final topFoods = (foodFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
        .take(3)
        .map((e) => e.key)
        .toList();
      if (topFoods.isNotEmpty) {
        insights.add(
          '🥗 Foods on your best days: "${topFoods.join(", ")}" appeared frequently on well-controlled days. '
          'Continue incorporating these and monitor how new foods affect your readings.',
        );
      }
    }

    // Glucose trend insight
    final allAvgGlucose = summaries
        .where((s) => s.avgGlucoseBefore > 0)
        .map((s) => s.avgGlucoseBefore)
        .toList();
    if (allAvgGlucose.length >= 7) {
      final recent = _avg(allAvgGlucose.sublist(allAvgGlucose.length - 7));
      final earlier = _avg(allAvgGlucose.sublist(0, allAvgGlucose.length - 7));
      if (recent < earlier - 10) {
        insights.add(
          '📉 Positive trend: Your average glucose has dropped ~${(earlier - recent).toStringAsFixed(0)} mg/dL '
          'over the past week. Your current habits are working — keep it up!',
        );
      } else if (recent > earlier + 10) {
        insights.add(
          '📈 Rising trend: Your average glucose has increased ~${(recent - earlier).toStringAsFixed(0)} mg/dL '
          'recently. Review recent food logs and activity — consider consulting your doctor.',
        );
      }
    }

    // Blood pressure insight
    final highBpDays = summaries
        .where((s) => s.vitals?.systolic != null && s.vitals!.systolic! > 130)
        .length;
    if (highBpDays > 3) {
      insights.add(
        '❤️ Blood pressure check: You had elevated BP (>130 mmHg systolic) on $highBpDays days this month. '
        'Reduce sodium intake, manage stress, and discuss with your physician if persistent.',
      );
    }

    // Add general actionable tips
    insights.addAll(_generalTips());

    return insights;
  }

  List<String> _generalTips() => [
    '🥦 Dietary tip: Prioritize low-glycemic foods — leafy greens, legumes, nuts, and whole grains. '
    'Avoid white rice, sugary drinks, and processed snacks which spike blood sugar rapidly.',
    '💧 Hydration: Drink 8–10 glasses of water daily. Dehydration can falsely elevate blood glucose readings.',
    '🏃 Exercise goal: Aim for at least 150 minutes of moderate activity per week — that\'s 30 minutes, 5 days. '
    'Even a 10-minute walk after each meal significantly lowers post-meal glucose spikes.',
    '⏰ Meal timing: Eating at consistent times helps stabilize blood sugar. Avoid long gaps (>5 hrs) between meals.',
    '🧘 Stress management: Chronic stress raises cortisol, which increases blood sugar. '
    'Consider 10-minute mindfulness, deep breathing, or light stretching daily.',
  ];

  String _noDataInsight() =>
    '📋 Start logging your meals, glucose readings, and activity daily. '
    'After a week of data, you\'ll see personalized AI insights about what\'s working for your body.';

  double _avg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Finds best-controlled days with highlights
  List<Map<String, dynamic>> getBestDays(List<DailySummary> summaries, {int limit = 5}) {
    final controlled = summaries
        .where((s) => s.isGlucoseControlled)
        .toList()
      ..sort((a, b) => a.avgGlucoseBefore.compareTo(b.avgGlucoseBefore));

    return controlled.take(limit).map((s) {
      final reasons = <String>[];
      if (s.activity?.walkingMinutes != null && s.activity!.walkingMinutes! >= 20) {
        reasons.add('${s.activity!.walkingMinutes} min walk');
      }
      if (s.activity?.screenTimeHours != null && s.activity!.screenTimeHours! <= 4) {
        reasons.add('Low screen time');
      }
      if (s.activity?.totalSleepHours != null && s.activity!.totalSleepHours >= 7) {
        reasons.add('Good sleep');
      }
      if (s.foodEntries.isNotEmpty) {
        reasons.add('${s.foodEntries.length} meals logged');
      }

      return {
        'date': s.date,
        'avgGlucose': s.avgGlucoseBefore,
        'reasons': reasons,
        'summary': s,
      };
    }).toList();
  }
}
