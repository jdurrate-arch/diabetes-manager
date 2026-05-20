import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class FoodLogDialog extends StatefulWidget {
  final FoodEntry? entry; // null = new, non-null = edit
  final String defaultMealType;

  const FoodLogDialog({
    super.key,
    this.entry,
    this.defaultMealType = 'breakfast',
  });

  @override
  State<FoodLogDialog> createState() => _FoodLogDialogState();
}

class _FoodLogDialogState extends State<FoodLogDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _foodCtrl;
  late TextEditingController _caloriesCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _glucoseBeforeCtrl;
  late TextEditingController _glucoseAfterCtrl;
  late TextEditingController _notesCtrl;
  late String _mealType;

  @override
  void initState() {
    super.initState();
    _mealType = widget.entry?.mealType ?? widget.defaultMealType;
    _foodCtrl = TextEditingController(text: widget.entry?.foodDescription ?? '');
    _caloriesCtrl = TextEditingController(text: widget.entry?.calories?.toStringAsFixed(0) ?? '');
    _carbsCtrl = TextEditingController(text: widget.entry?.carbs?.toStringAsFixed(0) ?? '');
    _glucoseBeforeCtrl = TextEditingController(text: widget.entry?.glucoseBefore?.toStringAsFixed(0) ?? '');
    _glucoseAfterCtrl = TextEditingController(text: widget.entry?.glucoseAfter?.toStringAsFixed(0) ?? '');
    _notesCtrl = TextEditingController(text: widget.entry?.notes ?? '');
  }

  @override
  void dispose() {
    _foodCtrl.dispose();
    _caloriesCtrl.dispose();
    _carbsCtrl.dispose();
    _glucoseBeforeCtrl.dispose();
    _glucoseAfterCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();
    final entry = FoodEntry(
      id: widget.entry?.id,
      date: provider.selectedDateStr,
      mealType: _mealType,
      foodDescription: _foodCtrl.text.trim(),
      calories: _caloriesCtrl.text.isNotEmpty ? double.tryParse(_caloriesCtrl.text) : null,
      carbs: _carbsCtrl.text.isNotEmpty ? double.tryParse(_carbsCtrl.text) : null,
      glucoseBefore: _glucoseBeforeCtrl.text.isNotEmpty ? double.tryParse(_glucoseBeforeCtrl.text) : null,
      glucoseAfter: _glucoseAfterCtrl.text.isNotEmpty ? double.tryParse(_glucoseAfterCtrl.text) : null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (widget.entry == null) {
      provider.addFoodEntry(entry);
    } else {
      provider.updateFoodEntry(entry);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entry != null;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Food Entry' : 'Log Food',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meal type selector
                    Text(
                      'Meal Type',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        MealTypeChip(
                          label: 'Breakfast',
                          icon: Icons.wb_sunny_rounded,
                          selected: _mealType == 'breakfast',
                          color: const Color(0xFFFFA726),
                          onTap: () => setState(() => _mealType = 'breakfast'),
                        ),
                        MealTypeChip(
                          label: 'Lunch',
                          icon: Icons.wb_cloudy_rounded,
                          selected: _mealType == 'lunch',
                          color: const Color(0xFF26A69A),
                          onTap: () => setState(() => _mealType = 'lunch'),
                        ),
                        MealTypeChip(
                          label: 'Dinner',
                          icon: Icons.nights_stay_rounded,
                          selected: _mealType == 'dinner',
                          color: const Color(0xFF7E57C2),
                          onTap: () => setState(() => _mealType = 'dinner'),
                        ),
                        MealTypeChip(
                          label: 'Snack',
                          icon: Icons.local_cafe_rounded,
                          selected: _mealType == 'snack',
                          color: const Color(0xFFEC407A),
                          onTap: () => setState(() => _mealType = 'snack'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    LabeledTextField(
                      label: 'Food Description *',
                      hint: 'e.g., Brown rice with vegetables, 1 cup',
                      controller: _foodCtrl,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe the food' : null,
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledTextField(
                            label: 'Calories (kcal)',
                            hint: '0',
                            controller: _caloriesCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledTextField(
                            label: 'Carbs (g)',
                            hint: '0',
                            controller: _carbsCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bloodtype_rounded, size: 16, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Blood Glucose Readings',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: LabeledTextField(
                                  label: 'Before Meal (mg/dL)',
                                  hint: 'e.g., 95',
                                  controller: _glucoseBeforeCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                                  validator: (v) {
                                    if (v != null && v.isNotEmpty) {
                                      final val = double.tryParse(v);
                                      if (val == null || val < 20 || val > 600) return 'Invalid (20–600)';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: LabeledTextField(
                                  label: '2h After Meal (mg/dL)',
                                  hint: 'e.g., 130',
                                  controller: _glucoseAfterCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                                  validator: (v) {
                                    if (v != null && v.isNotEmpty) {
                                      final val = double.tryParse(v);
                                      if (val == null || val < 20 || val > 600) return 'Invalid (20–600)';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          // Live glucose preview
                          Builder(builder: (ctx) {
                            final before = double.tryParse(_glucoseBeforeCtrl.text);
                            final after = double.tryParse(_glucoseAfterCtrl.text);
                            if (before == null && after == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  if (before != null) GlucoseBadge(value: before),
                                  if (after != null) GlucoseBadge(value: after),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    LabeledTextField(
                      label: 'Notes (optional)',
                      hint: 'Any additional details...',
                      controller: _notesCtrl,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: Icon(isEdit ? Icons.check_rounded : Icons.add_rounded, size: 18),
                      label: Text(isEdit ? 'Save Changes' : 'Log Food'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
