import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/insights_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifService = NotificationService();
  final InsightsService _insightsService = InsightsService();

  // ─── Selected Date ────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String get selectedDateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get selectedDateDisplay => DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    loadDayData();
    notifyListeners();
  }

  // ─── Daily Data ───────────────────────────────────────────
  List<FoodEntry> _foodEntries = [];
  VitalsEntry? _vitals;
  ActivityEntry? _activity;
  bool _isDayLoading = false;

  List<FoodEntry> get foodEntries => _foodEntries;
  VitalsEntry? get vitals => _vitals;
  ActivityEntry? get activity => _activity;
  bool get isDayLoading => _isDayLoading;

  List<FoodEntry> get breakfastEntries => _foodEntries.where((e) => e.mealType == 'breakfast').toList();
  List<FoodEntry> get lunchEntries => _foodEntries.where((e) => e.mealType == 'lunch').toList();
  List<FoodEntry> get dinnerEntries => _foodEntries.where((e) => e.mealType == 'dinner').toList();
  List<FoodEntry> get snackEntries => _foodEntries.where((e) => e.mealType == 'snack').toList();

  Future<void> loadDayData() async {
    _isDayLoading = true;
    notifyListeners();

    final date = selectedDateStr;
    _foodEntries = await _db.getFoodEntriesForDate(date);
    _vitals = await _db.getVitalsForDate(date);
    _activity = await _db.getActivityForDate(date);

    _isDayLoading = false;
    notifyListeners();
  }

  Future<void> addFoodEntry(FoodEntry entry) async {
    await _db.insertFoodEntry(entry);
    await loadDayData();
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    await _db.updateFoodEntry(entry);
    await loadDayData();
  }

  Future<void> deleteFoodEntry(int id) async {
    await _db.deleteFoodEntry(id);
    await loadDayData();
  }

  Future<void> saveVitals(VitalsEntry entry) async {
    await _db.upsertVitals(entry);
    _vitals = await _db.getVitalsForDate(selectedDateStr);
    notifyListeners();
  }

  Future<void> saveActivity(ActivityEntry entry) async {
    await _db.upsertActivity(entry);
    _activity = await _db.getActivityForDate(selectedDateStr);
    notifyListeners();
  }

  // ─── Notifications ────────────────────────────────────────
  List<NotificationSetting> _notifications = [];
  bool _notifLoading = false;

  List<NotificationSetting> get notifications => _notifications;
  bool get notifLoading => _notifLoading;

  Future<void> loadNotifications() async {
    _notifLoading = true;
    notifyListeners();
    _notifications = await _db.getAllNotifications();
    _notifLoading = false;
    notifyListeners();
  }

  Future<void> addNotification(NotificationSetting setting) async {
    final id = await _db.insertNotification(setting);
    final saved = setting.copyWith(id: id);
    await _notifService.scheduleNotification(saved);
    await loadNotifications();
  }

  Future<void> updateNotification(NotificationSetting setting) async {
    await _db.updateNotification(setting);
    if (setting.isEnabled) {
      await _notifService.scheduleNotification(setting);
    } else {
      await _notifService.cancelNotification(setting.id!);
    }
    await loadNotifications();
  }

  Future<void> toggleNotification(NotificationSetting setting) async {
    final updated = setting.copyWith(isEnabled: !setting.isEnabled);
    await updateNotification(updated);
  }

  Future<void> deleteNotification(int id) async {
    await _notifService.cancelNotification(id);
    await _db.deleteNotification(id);
    await loadNotifications();
  }

  // ─── Analytics ────────────────────────────────────────────
  int _analyticsYear = DateTime.now().year;
  int _analyticsMonth = DateTime.now().month;
  List<DailySummary> _monthlySummaries = [];
  Map<String, dynamic> _analyticsSummary = {};
  List<String> _insights = [];
  List<Map<String, dynamic>> _bestDays = [];
  bool _analyticsLoading = false;

  int get analyticsYear => _analyticsYear;
  int get analyticsMonth => _analyticsMonth;
  List<DailySummary> get monthlySummaries => _monthlySummaries;
  Map<String, dynamic> get analyticsSummary => _analyticsSummary;
  List<String> get insights => _insights;
  List<Map<String, dynamic>> get bestDays => _bestDays;
  bool get analyticsLoading => _analyticsLoading;

  String get analyticsMonthLabel =>
      DateFormat('MMMM yyyy').format(DateTime(_analyticsYear, _analyticsMonth));

  Future<void> loadAnalytics({int? year, int? month}) async {
    if (year != null) _analyticsYear = year;
    if (month != null) _analyticsMonth = month;

    _analyticsLoading = true;
    notifyListeners();

    _analyticsSummary = await _db.getAnalyticsSummary(_analyticsYear, _analyticsMonth);
    _monthlySummaries = (_analyticsSummary['summaries'] as List<DailySummary>?) ?? [];
    _insights = _insightsService.generateInsights(_monthlySummaries);
    _bestDays = _insightsService.getBestDays(_monthlySummaries);

    _analyticsLoading = false;
    notifyListeners();
  }

  void navigateAnalyticsMonth(int delta) {
    var newMonth = _analyticsMonth + delta;
    var newYear = _analyticsYear;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    loadAnalytics(year: newYear, month: newMonth);
  }

  // ─── Latest Vitals (for quick display) ───────────────────
  VitalsEntry? _latestVitals;
  VitalsEntry? get latestVitals => _latestVitals;

  Future<void> loadLatestVitals() async {
    _latestVitals = await _db.getLatestVitals();
    notifyListeners();
  }

  // ─── Init ─────────────────────────────────────────────────
  Future<void> initialize() async {
    await _notifService.initialize();
    await loadDayData();
    await loadNotifications();
    await loadLatestVitals();

    // Reschedule all enabled notifications
    final enabled = _notifications.where((n) => n.isEnabled).toList();
    await _notifService.rescheduleAll(enabled);
  }
}
