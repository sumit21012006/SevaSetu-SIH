/// Identity / citizen profile model used to personalise eligibility and
/// document recommendations. No unnecessary sensitive fields are stored.
library;

enum Occupation {
  student('Student'),
  farmer('Farmer'),
  privateEmployee('Private Employee'),
  governmentEmployee('Government Employee'),
  selfEmployed('Self-employed'),
  homemaker('Homemaker'),
  unemployed('Looking for work'),
  other('Other');

  const Occupation(this.label);
  final String label;
}

enum EducationLevel {
  secondary('Class 10 or below'),
  hsc('Class 12 (HSC)'),
  undergrad('Undergraduate'),
  postgrad('Postgraduate'),
  diploma('Diploma / Vocational'),
  other('Other');

  const EducationLevel(this.label);
  final String label;
}

enum CasteCategory {
  general('General'),
  obc('OBC'),
  sc('SC'),
  st('ST');

  const CasteCategory(this.label);
  final String label;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.state,
    required this.district,
    required this.occupation,
    required this.education,
    required this.annualIncomeLakhs,
    required this.casteCategory,
    this.familySize = 1,
    this.phone,
  });

  final String id;
  final String name;
  final int age;
  final String state;
  final String district;
  final Occupation occupation;
  final EducationLevel education;
  final double annualIncomeLakhs;
  final CasteCategory casteCategory;
  final int familySize;
  final String? phone;

  bool get isStudent => occupation == Occupation.student;

  UserProfile copyWith({
    String? name,
    int? age,
    String? state,
    String? district,
    Occupation? occupation,
    EducationLevel? education,
    double? annualIncomeLakhs,
    CasteCategory? casteCategory,
    int? familySize,
    String? phone,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      state: state ?? this.state,
      district: district ?? this.district,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      annualIncomeLakhs: annualIncomeLakhs ?? this.annualIncomeLakhs,
      casteCategory: casteCategory ?? this.casteCategory,
      familySize: familySize ?? this.familySize,
      phone: phone ?? this.phone,
    );
  }
}
