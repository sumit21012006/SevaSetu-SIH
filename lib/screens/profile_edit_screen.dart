import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/profile.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  Occupation _occupation = Occupation.student;
  EducationLevel _education = EducationLevel.undergrad;
  CasteCategory _caste = CasteCategory.general;
  double _incomeLakhs = 3.4;
  int _familySize = 4;
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _district;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    final p = AppScope.of(context).profile;
    _name = TextEditingController(text: p.name);
    _age = TextEditingController(text: '${p.age}');
    _district = TextEditingController(text: p.district);
    _occupation = p.occupation;
    _education = p.education;
    _caste = p.casteCategory;
    _incomeLakhs = p.annualIncomeLakhs;
    _familySize = p.familySize;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _district.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          const Text(
            'Only fields used for eligibility and document matching are '
            'asked. Nothing sensitive is stored.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.inkFaint,
              height: 1.4,
            ),
          ),
          const Gap(AppSpacing.lg),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const Gap(AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _district,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          _dropdown<Occupation>(
            value: _occupation,
            icon: Icons.work_outline_rounded,
            label: 'Occupation',
            items: Occupation.values,
            labelOf: (o) => o.label,
            onChanged: (v) => setState(() => _occupation = v!),
          ),
          const Gap(AppSpacing.md),
          _dropdown<EducationLevel>(
            value: _education,
            icon: Icons.school_outlined,
            label: 'Education',
            items: EducationLevel.values,
            labelOf: (e) => e.label,
            onChanged: (v) => setState(() => _education = v!),
          ),
          const Gap(AppSpacing.md),
          _dropdown<CasteCategory>(
            value: _caste,
            icon: Icons.groups_outlined,
            label: 'Caste category',
            items: CasteCategory.values,
            labelOf: (c) => c.label,
            onChanged: (v) => setState(() => _caste = v!),
          ),
          const Gap(AppSpacing.md),
          Text(
            'Family annual income: ₹${_incomeLakhs == _incomeLakhs.roundToDouble() ? _incomeLakhs.round() : _incomeLakhs.toStringAsFixed(1)} lakh',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Slider(
            value: _incomeLakhs,
            min: 0.5,
            max: 20,
            divisions: 39,
            label: '₹${_incomeLakhs.toStringAsFixed(1)}L',
            onChanged: (v) => setState(() => _incomeLakhs = v),
          ),
          const Gap(AppSpacing.md),
          _dropdown<int>(
            value: _familySize,
            icon: Icons.family_restroom_rounded,
            label: 'Family size',
            items: [for (var i = 1; i <= 10; i++) i],
            labelOf: (i) => '$i member${i == 1 ? '' : 's'}',
            onChanged: (v) => setState(() => _familySize = v!),
          ),
          const Gap(AppSpacing.xl),
          FilledButton.icon(
            onPressed: () async {
              final updated = UserProfile(
                id: state.profile.id,
                name: _name.text.trim().isEmpty
                    ? state.profile.name
                    : _name.text.trim(),
                age: int.tryParse(_age.text.trim()) ?? state.profile.age,
                state: state.profile.state,
                district: _district.text.trim().isEmpty
                    ? state.profile.district
                    : _district.text.trim(),
                occupation: _occupation,
                education: _education,
                annualIncomeLakhs: _incomeLakhs,
                casteCategory: _caste,
                familySize: _familySize,
              );
              await state.updateProfile(updated);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Profile updated — eligibility and readiness now reflect '
                    'your details.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required IconData icon,
    required String label,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
      ],
      onChanged: onChanged,
    );
  }
}
