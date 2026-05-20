import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/food_log_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          DatePickerHeader(
            selectedDate: provider.selectedDate,
            onDateSelected: provider.setSelectedDate,
          ),
          Expanded(
            child: provider.isDayLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: provider.loadDayData,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        const SizedBox(height: 8),
                        _DailySummaryBanner(provider: provider),
                        _FoodLogSection(provider: provider),
                        _VitalsSection(provider: provider),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Daily Summary Banner ─────────────────────────────────────

class _DailySummaryBanner extends StatelessWidget {
  final AppProvider provider;
  const _DailySummaryBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final entries = provider.foodEntries;
    final vitals = provider.vitals;
    final activity = provider.activity;

    if (entries.isEmpty && vitals == null && activity == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No data logged yet for this day. Start by adding a meal or your vitals!',
                  style: GoogleFonts.nunito(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final allGlucose = entries
        .where((e) => e.glucoseBefore != null)
        .map((e) => e.glucoseBefore!)
        .toList();
    final avgGlucose = allGlucose.isNotEmpty
        ? allGlucose.reduce((a, b) => a + b) / allGlucose.length
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day at a Glance',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BannerStat(
                    icon: Icons.restaurant_rounded,
                    value: '${entries.length}',
                    label: 'Meals Logged',
                  ),
                ),
                if (avgGlucose != null) ...[
                  _vDivider(),
                  Expanded(
                    child: _BannerStat(
                      icon: Icons.bloodtype_rounded,
                      value: avgGlucose.toStringAsFixed(0),
                      label: 'Avg Glucose\nmg/dL',
                      statusColor: AppTheme.glucoseColor(avgGlucose),
                    ),
                  ),
                ],
                if (vitals?.weight != null) ...[
                  _vDivider(),
                  Expanded(
                    child: _BannerStat(
                      icon: Icons.monitor_weight_rounded,
                      value: '${vitals!.weight!.toStringAsFixed(1)}',
                      label: 'Weight\n(kg)',
                    ),
                  ),
                ],
                if (activity?.totalActiveMinutes != null && activity!.totalActiveMinutes > 0) ...[
                  _vDivider(),
                  Expanded(
                    child: _BannerStat(
                      icon: Icons.directions_walk_rounded,
                      value: '${activity.totalActiveMinutes}',
                      label: 'Active\nMinutes',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1, height: 40, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _BannerStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? statusColor;

  const _BannerStat({required this.icon, required this.value, required this.label, this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: statusColor ?? Colors.white,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}

// ─── Food Log Section ─────────────────────────────────────────

class _FoodLogSection extends StatelessWidget {
  final AppProvider provider;
  const _FoodLogSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Food Log',
      icon: Icons.restaurant_rounded,
      iconColor: const Color(0xFFFFA726),
      trailing: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primarySurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.add, color: AppTheme.primary, size: 20),
        ),
        onPressed: () => _showAddFoodDialog(context),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      children: [
        _MealSection(
          title: 'Breakfast',
          icon: Icons.wb_sunny_rounded,
          color: const Color(0xFFFFA726),
          entries: provider.breakfastEntries,
          mealType: 'breakfast',
          provider: provider,
        ),
        _MealSection(
          title: 'Lunch',
          icon: Icons.wb_cloudy_rounded,
          color: const Color(0xFF26A69A),
          entries: provider.lunchEntries,
          mealType: 'lunch',
          provider: provider,
        ),
        _MealSection(
          title: 'Dinner',
          icon: Icons.nights_stay_rounded,
          color: const Color(0xFF7E57C2),
          entries: provider.dinnerEntries,
          mealType: 'dinner',
          provider: provider,
        ),
        _MealSection(
          title: 'Snacks',
          icon: Icons.local_cafe_rounded,
          color: const Color(0xFFEC407A),
          entries: provider.snackEntries,
          mealType: 'snack',
          provider: provider,
        ),
      ],
    );
  }

  void _showAddFoodDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FoodLogDialog(),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<FoodEntry> entries;
  final String mealType;
  final AppProvider provider;

  const _MealSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.entries,
    required this.mealType,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => FoodLogDialog(defaultMealType: mealType),
              ),
              child: Text(
                '+ Add',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.12), style: BorderStyle.solid),
              ),
              child: Center(
                child: Text(
                  'No $title logged',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textHint),
                ),
              ),
            ),
          )
        else
          ...entries.map((e) => FoodEntryCard(
            entry: e,
            onEdit: () => showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => FoodLogDialog(entry: e),
            ),
            onDelete: () => _confirmDelete(context, e.id!),
          )),
        const Divider(height: 20),
      ],
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Entry?', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: Text('This food log entry will be permanently deleted.', style: GoogleFonts.nunito()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.deleteFoodEntry(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Vitals Section ───────────────────────────────────────────

class _VitalsSection extends StatelessWidget {
  final AppProvider provider;
  const _VitalsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Vitals & Metrics',
      icon: Icons.favorite_rounded,
      iconColor: AppTheme.danger,
      trailing: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primarySurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            provider.vitals == null ? Icons.add : Icons.edit_outlined,
            color: AppTheme.primary,
            size: 20,
          ),
        ),
        onPressed: () => _showVitalsSheet(context),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      children: [
        if (provider.vitals == null)
          GestureDetector(
            onTap: () => _showVitalsSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Log Today\'s Vitals',
                      style: GoogleFonts.nunito(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Weight',
                  value: provider.vitals!.weight != null
                      ? provider.vitals!.weight!.toStringAsFixed(1)
                      : '—',
                  unit: 'kg',
                  icon: Icons.monitor_weight_outlined,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'BMI',
                  value: provider.vitals!.bmi != null
                      ? provider.vitals!.bmi!.toStringAsFixed(1)
                      : '—',
                  icon: Icons.accessibility_rounded,
                  color: AppTheme.success,
                  subtitle: provider.vitals!.bmiCategory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (provider.vitals!.systolic != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: provider.vitals!.systolic! > 130
                    ? AppTheme.warning.withOpacity(0.08)
                    : AppTheme.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: provider.vitals!.systolic! > 130
                      ? AppTheme.warning.withOpacity(0.3)
                      : AppTheme.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    color: provider.vitals!.systolic! > 130 ? AppTheme.warning : AppTheme.success,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Pressure',
                        style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${provider.vitals!.systolic}/${provider.vitals!.diastolic} mmHg',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: provider.vitals!.systolic! > 130 ? AppTheme.warning : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.vitals!.systolic! > 130
                          ? AppTheme.warning.withOpacity(0.15)
                          : AppTheme.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      provider.vitals!.systolic! > 140
                          ? 'High'
                          : provider.vitals!.systolic! > 130
                              ? 'Elevated'
                              : 'Normal',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: provider.vitals!.systolic! > 130 ? AppTheme.warning : AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          _ActivitySummary(provider: provider),
        ],
      ],
    );
  }

  void _showVitalsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VitalsAndActivitySheet(provider: provider),
    );
  }
}

// ─── Activity Summary (inside Vitals card) ───────────────────

class _ActivitySummary extends StatelessWidget {
  final AppProvider provider;
  const _ActivitySummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.activity == null) {
      return GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _VitalsAndActivitySheet(provider: provider),
        ),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.success.withOpacity(0.2)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: AppTheme.success, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Log Activity & Sleep',
                  style: GoogleFonts.nunito(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final act = provider.activity!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Activity & Sleep',
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (act.totalSleepHours > 0)
              _ActivityChip(
                icon: Icons.bedtime_rounded,
                label: '${act.totalSleepHours.toStringAsFixed(1)}h sleep',
                color: const Color(0xFF5C6BC0),
              ),
            if ((act.walkingMinutes ?? 0) > 0)
              _ActivityChip(
                icon: Icons.directions_walk_rounded,
                label: '${act.walkingMinutes} min walk',
                color: AppTheme.success,
              ),
            if ((act.exerciseMinutes ?? 0) > 0)
              _ActivityChip(
                icon: Icons.fitness_center_rounded,
                label: '${act.exerciseMinutes} min exercise',
                color: AppTheme.primary,
              ),
            if ((act.screenTimeHours ?? 0) > 0)
              _ActivityChip(
                icon: Icons.computer_rounded,
                label: '${act.screenTimeHours!.toStringAsFixed(1)}h screen',
                color: (act.screenTimeHours ?? 0) > 6 ? AppTheme.warning : AppTheme.textSecondary,
              ),
            if ((act.drivingHours ?? 0) > 0)
              _ActivityChip(
                icon: Icons.drive_eta_rounded,
                label: '${act.drivingHours!.toStringAsFixed(1)}h driving',
                color: AppTheme.textSecondary,
              ),
          ],
        ),
      ],
    );
  }
}

class _ActivityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActivityChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ─── Vitals & Activity Bottom Sheet ──────────────────────────

class _VitalsAndActivitySheet extends StatefulWidget {
  final AppProvider provider;
  const _VitalsAndActivitySheet({required this.provider});

  @override
  State<_VitalsAndActivitySheet> createState() => _VitalsAndActivitySheetState();
}

class _VitalsAndActivitySheetState extends State<_VitalsAndActivitySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Vitals controllers
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();

  // Activity controllers
  final _sleepTimeCtrl = TextEditingController();
  final _wakeTimeCtrl = TextEditingController();
  final _walkingCtrl = TextEditingController();
  final _exerciseCtrl = TextEditingController();
  final _screenCtrl = TextEditingController();
  final _drivingCtrl = TextEditingController();
  final _activityNotesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);

    final v = widget.provider.vitals;
    if (v != null) {
      _weightCtrl.text = v.weight?.toStringAsFixed(1) ?? '';
      _heightCtrl.text = v.height?.toStringAsFixed(1) ?? '';
      _systolicCtrl.text = v.systolic?.toString() ?? '';
      _diastolicCtrl.text = v.diastolic?.toString() ?? '';
      _heartRateCtrl.text = v.heartRate?.toString() ?? '';
    } else {
      // Pre-fill from latest vitals
      final latest = widget.provider.latestVitals;
      if (latest != null) {
        _heightCtrl.text = latest.height?.toStringAsFixed(1) ?? '';
        _weightCtrl.text = latest.weight?.toStringAsFixed(1) ?? '';
      }
    }

    final a = widget.provider.activity;
    if (a != null) {
      _sleepTimeCtrl.text = a.sleepTime ?? '';
      _wakeTimeCtrl.text = a.wakeTime ?? '';
      _walkingCtrl.text = a.walkingMinutes?.toString() ?? '';
      _exerciseCtrl.text = a.exerciseMinutes?.toString() ?? '';
      _screenCtrl.text = a.screenTimeHours?.toStringAsFixed(1) ?? '';
      _drivingCtrl.text = a.drivingHours?.toStringAsFixed(1) ?? '';
      _activityNotesCtrl.text = a.activityNotes ?? '';
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _weightCtrl.dispose(); _heightCtrl.dispose(); _systolicCtrl.dispose();
    _diastolicCtrl.dispose(); _heartRateCtrl.dispose();
    _sleepTimeCtrl.dispose(); _wakeTimeCtrl.dispose();
    _walkingCtrl.dispose(); _exerciseCtrl.dispose();
    _screenCtrl.dispose(); _drivingCtrl.dispose(); _activityNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveVitals() async {
    final provider = widget.provider;
    final entry = VitalsEntry(
      date: provider.selectedDateStr,
      weight: _weightCtrl.text.isNotEmpty ? double.tryParse(_weightCtrl.text) : null,
      height: _heightCtrl.text.isNotEmpty ? double.tryParse(_heightCtrl.text) : null,
      systolic: _systolicCtrl.text.isNotEmpty ? int.tryParse(_systolicCtrl.text) : null,
      diastolic: _diastolicCtrl.text.isNotEmpty ? int.tryParse(_diastolicCtrl.text) : null,
      heartRate: _heartRateCtrl.text.isNotEmpty ? int.tryParse(_heartRateCtrl.text) : null,
    );
    await provider.saveVitals(entry);
    await provider.loadLatestVitals();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Vitals saved!'), backgroundColor: AppTheme.success),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveActivity() async {
    final provider = widget.provider;
    final entry = ActivityEntry(
      date: provider.selectedDateStr,
      sleepTime: _sleepTimeCtrl.text.isNotEmpty ? _sleepTimeCtrl.text : null,
      wakeTime: _wakeTimeCtrl.text.isNotEmpty ? _wakeTimeCtrl.text : null,
      walkingMinutes: _walkingCtrl.text.isNotEmpty ? int.tryParse(_walkingCtrl.text) : null,
      exerciseMinutes: _exerciseCtrl.text.isNotEmpty ? int.tryParse(_exerciseCtrl.text) : null,
      screenTimeHours: _screenCtrl.text.isNotEmpty ? double.tryParse(_screenCtrl.text) : null,
      drivingHours: _drivingCtrl.text.isNotEmpty ? double.tryParse(_drivingCtrl.text) : null,
      activityNotes: _activityNotesCtrl.text.trim().isEmpty ? null : _activityNotesCtrl.text.trim(),
    );
    await provider.saveActivity(entry);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Activity saved!'), backgroundColor: AppTheme.success),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Text(
                  'Log Health Data',
                  style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Vitals & Metrics'),
              Tab(text: 'Sleep & Activity'),
            ],
          ),
          const Divider(height: 1),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildVitalsTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Weight (kg)',
                  hint: 'e.g., 75.5',
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledTextField(
                  label: 'Height (cm)',
                  hint: 'e.g., 170',
                  controller: _heightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Blood Pressure',
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Systolic (mmHg)',
                  hint: 'e.g., 120',
                  controller: _systolicCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledTextField(
                  label: 'Diastolic (mmHg)',
                  hint: 'e.g., 80',
                  controller: _diastolicCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LabeledTextField(
            label: 'Heart Rate (bpm)',
            hint: 'e.g., 72',
            controller: _heartRateCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveVitals,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Vitals'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sleep Cycle', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Sleep Time',
                  hint: 'HH:MM',
                  controller: _sleepTimeCtrl,
                  readOnly: true,
                  onTap: () => _pickTime(_sleepTimeCtrl),
                  prefix: const Icon(Icons.bedtime_rounded, color: Color(0xFF5C6BC0), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledTextField(
                  label: 'Wake Time',
                  hint: 'HH:MM',
                  controller: _wakeTimeCtrl,
                  readOnly: true,
                  onTap: () => _pickTime(_wakeTimeCtrl),
                  prefix: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFA726), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Physical Activity', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Walking (min)',
                  hint: '0',
                  controller: _walkingCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  prefix: const Icon(Icons.directions_walk_rounded, color: AppTheme.success, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledTextField(
                  label: 'Exercise (min)',
                  hint: '0',
                  controller: _exerciseCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  prefix: const Icon(Icons.fitness_center_rounded, color: AppTheme.primary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Sedentary Time', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Screen Time (hrs)',
                  hint: '0.0',
                  controller: _screenCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                  prefix: const Icon(Icons.computer_rounded, color: AppTheme.textSecondary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledTextField(
                  label: 'Driving (hrs)',
                  hint: '0.0',
                  controller: _drivingCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                  prefix: const Icon(Icons.drive_eta_rounded, color: AppTheme.textSecondary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LabeledTextField(
            label: 'Activity Notes',
            hint: 'Any other observations...',
            controller: _activityNotesCtrl,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveActivity,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Activity'),
            ),
          ),
        ],
      ),
    );
  }
}
