import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _diabetesTypeCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _targetFastingCtrl = TextEditingController();
  final _targetPostMealCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('user_name') ?? '';
      _ageCtrl.text = prefs.getString('user_age') ?? '';
      _diabetesTypeCtrl.text = prefs.getString('diabetes_type') ?? 'Type 2';
      _doctorCtrl.text = prefs.getString('doctor_name') ?? '';
      _targetFastingCtrl.text = prefs.getString('target_fasting') ?? '80–130';
      _targetPostMealCtrl.text = prefs.getString('target_post_meal') ?? '< 180';
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameCtrl.text.trim());
    await prefs.setString('user_age', _ageCtrl.text.trim());
    await prefs.setString('diabetes_type', _diabetesTypeCtrl.text.trim());
    await prefs.setString('doctor_name', _doctorCtrl.text.trim());
    await prefs.setString('target_fasting', _targetFastingCtrl.text.trim());
    await prefs.setString('target_post_meal', _targetPostMealCtrl.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _diabetesTypeCtrl.dispose();
    _doctorCtrl.dispose();
    _targetFastingCtrl.dispose();
    _targetPostMealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _savePrefs,
            child: Text(
              'Save',
              style: GoogleFonts.nunito(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                _buildProfileHeader(),
                _buildProfileSection(),
                _buildGlucoseTargetsSection(),
                _buildAboutSection(),
                _buildDataSection(context),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _diabetesTypeCtrl.text.isNotEmpty
                      ? _diabetesTypeCtrl.text
                      : 'Diabetes Type',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return SectionCard(
      title: 'Personal Profile',
      icon: Icons.person_outline_rounded,
      iconColor: AppTheme.primary,
      children: [
        LabeledTextField(
          label: 'Full Name',
          hint: 'Enter your name',
          controller: _nameCtrl,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LabeledTextField(
                label: 'Age',
                hint: 'Years',
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diabetes Type',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: ['Type 1', 'Type 2', 'Gestational', 'Pre-diabetic', 'Other']
                            .contains(_diabetesTypeCtrl.text)
                        ? _diabetesTypeCtrl.text
                        : 'Type 2',
                    decoration: const InputDecoration(),
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    items: ['Type 1', 'Type 2', 'Gestational', 'Pre-diabetic', 'Other']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _diabetesTypeCtrl.text = v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LabeledTextField(
          label: "Doctor's Name (optional)",
          hint: "Dr. Smith",
          controller: _doctorCtrl,
        ),
      ],
    );
  }

  Widget _buildGlucoseTargetsSection() {
    return SectionCard(
      title: 'Glucose Targets',
      icon: Icons.bloodtype_rounded,
      iconColor: AppTheme.danger,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Default ADA targets: Fasting 80–130 mg/dL, Post-meal < 180 mg/dL. Adjust per your doctor\'s guidance.',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.primaryDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LabeledTextField(
                label: 'Fasting / Before Meal',
                hint: '80–130 mg/dL',
                controller: _targetFastingCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledTextField(
                label: '2h Post-Meal Target',
                hint: '< 180 mg/dL',
                controller: _targetPostMealCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Glucose Reference Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Reference',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _GlucoseRefRow(
                label: 'Low (Hypoglycemia)',
                range: '< 70 mg/dL',
                color: AppTheme.glucoseLow,
              ),
              _GlucoseRefRow(
                label: 'Normal (Fasting)',
                range: '70–99 mg/dL',
                color: AppTheme.glucoseNormal,
              ),
              _GlucoseRefRow(
                label: 'Pre-Diabetic (Fasting)',
                range: '100–125 mg/dL',
                color: AppTheme.warning,
              ),
              _GlucoseRefRow(
                label: 'Diabetic (Fasting)',
                range: '≥ 126 mg/dL',
                color: AppTheme.danger,
              ),
              _GlucoseRefRow(
                label: 'Post-Meal Target',
                range: '< 180 mg/dL',
                color: AppTheme.glucoseNormal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return SectionCard(
      title: 'About',
      icon: Icons.info_outline_rounded,
      iconColor: AppTheme.accent,
      children: [
        MetricTile(label: 'App Name', value: 'Diabetes Manager'),
        MetricTile(label: 'Version', value: '1.0.0'),
        MetricTile(label: 'Storage', value: 'Local (Offline Only)'),
        MetricTile(label: 'Data Privacy', value: 'On-device only'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.medical_information_outlined, color: AppTheme.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Medical Disclaimer: This app is a personal health tracking tool and is NOT a substitute for professional medical advice. Always consult your healthcare provider for medical decisions.',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return SectionCard(
      title: 'Data Management',
      icon: Icons.storage_rounded,
      iconColor: AppTheme.textSecondary,
      children: [
        _SettingsTile(
          icon: Icons.backup_rounded,
          iconColor: AppTheme.accent,
          label: 'All data is stored offline',
          subtitle: 'Your health data never leaves your device',
        ),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.lock_outline_rounded,
          iconColor: AppTheme.success,
          label: 'Private & Secure',
          subtitle: 'No internet connection required',
        ),
      ],
    );
  }
}

class _GlucoseRefRow extends StatelessWidget {
  final String label;
  final String range;
  final Color color;

  const _GlucoseRefRow({
    required this.label,
    required this.range,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Text(
            range,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  )),
              Text(subtitle,
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
