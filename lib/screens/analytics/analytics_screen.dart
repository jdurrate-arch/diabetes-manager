import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            onPressed: () => provider.navigateAnalyticsMonth(-1),
            tooltip: 'Previous Month',
          ),
          Center(
            child: Text(
              provider.analyticsMonthLabel,
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            onPressed: () => provider.navigateAnalyticsMonth(1),
            tooltip: 'Next Month',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          labelStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Charts'),
            Tab(text: 'AI Insights'),
          ],
        ),
      ),
      body: provider.analyticsLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _ChartsTab(provider: provider),
                _InsightsTab(provider: provider),
              ],
            ),
    );
  }
}

// ─── Charts Tab ───────────────────────────────────────────────

class _ChartsTab extends StatelessWidget {
  final AppProvider provider;
  const _ChartsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.monthlySummaries.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.bar_chart_rounded,
        title: 'No Data This Month',
        subtitle: 'Start logging your daily health data to see trends and analytics here.',
      );
    }

    final summary = provider.analyticsSummary;

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _SummaryStatsGrid(summary: summary),
        _GlucoseChart(summaries: provider.monthlySummaries),
        _WeightChart(summaries: provider.monthlySummaries),
        _ActivityChart(summaries: provider.monthlySummaries),
        _ControlledDaysHighlight(provider: provider),
      ],
    );
  }
}

class _SummaryStatsGrid extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryStatsGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final avgGlucose = (summary['avgGlucose'] as double?) ?? 0.0;
    final controlled = (summary['controlledDays'] as int?) ?? 0;
    final total = (summary['totalDaysLogged'] as int?) ?? 0;
    final avgWalking = (summary['avgWalkingMinutes'] as double?) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Avg Glucose',
                  value: avgGlucose > 0 ? avgGlucose.toStringAsFixed(0) : '—',
                  unit: avgGlucose > 0 ? 'mg/dL' : '',
                  icon: Icons.bloodtype_rounded,
                  color: avgGlucose > 0 ? AppTheme.glucoseColor(avgGlucose) : AppTheme.textSecondary,
                  subtitle: avgGlucose > 0 ? AppTheme.glucoseStatus(avgGlucose) : 'No readings',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Controlled Days',
                  value: '$controlled / $total',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.success,
                  subtitle: total > 0 ? '${(controlled / total * 100).toStringAsFixed(0)}% of logged days' : '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Days Logged',
                  value: '$total',
                  icon: Icons.calendar_today_rounded,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Avg Walking',
                  value: avgWalking > 0 ? avgWalking.toStringAsFixed(0) : '—',
                  unit: avgWalking > 0 ? 'min/day' : '',
                  icon: Icons.directions_walk_rounded,
                  color: AppTheme.primary,
                  subtitle: avgWalking >= 30 ? 'Meeting goal ✓' : avgWalking > 0 ? 'Goal: 30 min' : 'No data',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Glucose Line Chart ───────────────────────────────────────

class _GlucoseChart extends StatelessWidget {
  final List<DailySummary> summaries;
  const _GlucoseChart({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final dataPoints = summaries
        .asMap()
        .entries
        .where((e) => e.value.avgGlucoseBefore > 0)
        .toList();

    if (dataPoints.isEmpty) return const SizedBox.shrink();

    final beforeSpots = dataPoints
        .map((e) => FlSpot(e.key.toDouble(), e.value.avgGlucoseBefore))
        .toList();
    final afterSpots = dataPoints
        .where((e) => e.value.avgGlucoseAfter > 0)
        .map((e) => FlSpot(e.key.toDouble(), e.value.avgGlucoseAfter))
        .toList();

    return SectionCard(
      title: 'Blood Glucose Trend',
      icon: Icons.bloodtype_rounded,
      iconColor: AppTheme.danger,
      children: [
        // Legend
        Row(
          children: [
            _legend(AppTheme.primary, 'Before Meal'),
            const SizedBox(width: 16),
            if (afterSpots.isNotEmpty) _legend(AppTheme.warning, '2h After Meal'),
            const Spacer(),
            // Reference lines key
            _legend(AppTheme.danger.withOpacity(0.4), '> 140 High'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: AppTheme.divider,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 50,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.textHint),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (dataPoints.length / 5).ceilToDouble().clamp(1, 10),
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx >= 0 && idx < dataPoints.length) {
                        final date = DateTime.parse(dataPoints[idx].value.date);
                        return Text(
                          DateFormat('d').format(date),
                          style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.textHint),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 60,
              maxY: 300,
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(y: 70, color: AppTheme.glucoseLow.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5]),
                  HorizontalLine(y: 140, color: AppTheme.danger.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5]),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: beforeSpots,
                  isCurved: true,
                  color: AppTheme.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 3,
                      color: AppTheme.glucoseColor(spot.y),
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primary.withOpacity(0.08),
                  ),
                ),
                if (afterSpots.isNotEmpty)
                  LineChartBarData(
                    spots: afterSpots,
                    isCurved: true,
                    color: AppTheme.warning,
                    barWidth: 2,
                    dashArray: [6, 3],
                    dotData: const FlDotData(show: false),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final color = s.bar.color ?? AppTheme.primary;
                    return LineTooltipItem(
                      '${s.y.toStringAsFixed(0)} mg/dL',
                      GoogleFonts.nunito(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Weight Chart ─────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  final List<DailySummary> summaries;
  const _WeightChart({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final dataPoints = summaries
        .asMap()
        .entries
        .where((e) => e.value.vitals?.weight != null)
        .toList();

    if (dataPoints.isEmpty) return const SizedBox.shrink();

    final spots = dataPoints
        .map((e) => FlSpot(e.key.toDouble(), e.value.vitals!.weight!))
        .toList();

    final weights = spots.map((s) => s.y).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b) - 2;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 2;

    return SectionCard(
      title: 'Weight Trend',
      icon: Icons.monitor_weight_rounded,
      iconColor: AppTheme.accent,
      children: [
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.divider, strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.textHint)),
                  ),
                ),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: minW,
              maxY: maxW,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.accent,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3, color: AppTheme.accent, strokeWidth: 1.5, strokeColor: Colors.white),
                  ),
                  belowBarData: BarAreaData(show: true, color: AppTheme.accent.withOpacity(0.08)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${dataPoints.first.value.vitals!.weight!.toStringAsFixed(1)} kg (start)',
              style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textHint)),
            Text('${dataPoints.last.value.vitals!.weight!.toStringAsFixed(1)} kg (latest)',
              style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

// ─── Activity Bar Chart ───────────────────────────────────────

class _ActivityChart extends StatelessWidget {
  final List<DailySummary> summaries;
  const _ActivityChart({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final dataPoints = summaries
        .where((s) => s.activity?.totalActiveMinutes != null && s.activity!.totalActiveMinutes > 0)
        .take(20)
        .toList();

    if (dataPoints.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: 'Daily Activity (minutes)',
      icon: Icons.directions_walk_rounded,
      iconColor: AppTheme.success,
      children: [
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) {
                    final date = DateTime.parse(dataPoints[group.x].date);
                    return BarTooltipItem(
                      '${DateFormat('MMM d').format(date)}\n${rod.toY.toInt()} min',
                      GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 30,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.textHint)),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false,
                horizontalInterval: 30,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.divider, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(y: 30, color: AppTheme.success.withOpacity(0.4), strokeWidth: 1, dashArray: [4, 4]),
                ],
              ),
              barGroups: dataPoints.asMap().entries.map((e) {
                final active = e.value.activity!.totalActiveMinutes.toDouble();
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: active,
                      color: active >= 30 ? AppTheme.success : AppTheme.warning,
                      width: 14,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 4),
            Text('≥ 30 min (goal met)', style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(width: 12),
            Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.warning, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 4),
            Text('< 30 min', style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }
}

// ─── Controlled Days Highlight ────────────────────────────────

class _ControlledDaysHighlight extends StatelessWidget {
  final AppProvider provider;
  const _ControlledDaysHighlight({required this.provider});

  @override
  Widget build(BuildContext context) {
    final bestDays = provider.bestDays;
    if (bestDays.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: 'Best Controlled Days',
      icon: Icons.star_rounded,
      iconColor: const Color(0xFFFFB300),
      children: [
        Text(
          'Days with lowest/most stable glucose readings this month:',
          style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        ...bestDays.map((dayData) {
          final date = DateTime.parse(dayData['date'] as String);
          final glucose = dayData['avgGlucose'] as double;
          final reasons = dayData['reasons'] as List<String>;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('d').format(date),
                        style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.success)),
                      Text(DateFormat('MMM').format(date),
                        style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlucoseBadge(value: glucose),
                      if (reasons.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: reasons.map((r) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(r, style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.primaryDark, fontWeight: FontWeight.w600)),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── AI Insights Tab ──────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final AppProvider provider;
  const _InsightsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.insights.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.psychology_rounded,
        title: 'No Insights Yet',
        subtitle: 'Log at least one week of data to receive personalized AI health insights.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'AI Health Insights',
                    style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your ${provider.analyticsMonthLabel} data, here are personalized patterns and recommendations:',
                style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Insights list
        ...provider.insights.asMap().entries.map((e) {
          final insight = e.value;
          final isPositive = insight.startsWith('✅') || insight.startsWith('📉') || insight.startsWith('😴');
          final isWarning = insight.startsWith('⚠️') || insight.startsWith('📈') || insight.startsWith('❤️') || insight.startsWith('💻');

          Color cardColor = AppTheme.primary;
          if (isPositive) cardColor = AppTheme.success;
          if (isWarning) cardColor = AppTheme.warning;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: cardColor.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${e.key + 1}', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: cardColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.divider,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'These insights are generated from your logged data patterns. Always consult a healthcare professional before making medical decisions.',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
