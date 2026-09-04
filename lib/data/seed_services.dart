import '../models/document.dart';
import '../models/profile.dart';
import '../models/service.dart';

/// Seed catalogue: realistic government services with personalised
/// eligibility rules, required documents and application guidance.
List<GovService> buildSeedServices({DateTime? now}) {
  final t = now ?? DateTime.now();

  final ay = t.month >= 7 ? t.year + 1 : t.year; // application year label

  return [
    GovService(
      id: 'svc-pms',
      name: 'Post-Matric Scholarship',
      shortDescription:
          'Scholarship for students from OBC/SC/ST & minority communities '
          'continuing education after Class 10.',
      description:
          'The Post-Matric Scholarship supports students from economically '
          'weaker families to continue education from Class 11 up to '
          'post-graduation. Tuition and non-refundable fees are covered, and '
          'a maintenance allowance is credited directly to the student\'s bank '
          'account each year. SevaSetu helps you prepare the documents the '
          'scholarship portal requires before you apply.',
      category: ServiceCategory.education,
      department: 'Department of Higher & Technical Education, Maharashtra',
      scope: 'Maharashtra',
      keywords: [
        'scholarship',
        'student',
        'college',
        'fees',
        'education',
        'post matric',
        'chhatravrutti',
        'शिष्यवृत्ती',
        'छात्रवृत्ति',
        'शिक्षण',
        'money for study',
      ],
      requiredDocuments: const [
        DocumentRequirement(
          type: DocumentType.aadhaar,
          why: 'Primary identity for the scholarship account on the portal.',
        ),
        DocumentRequirement(
          type: DocumentType.domicile,
          why: 'Confirms Maharashtra residence for state scholarship.',
        ),
        DocumentRequirement(
          type: DocumentType.marksheet,
          why: 'Previous-year marksheet proves continuing education.',
        ),
        DocumentRequirement(
          type: DocumentType.caste,
          why: 'Category certificate is needed for OBC/SC/ST quota.',
        ),
        DocumentRequirement(
          type: DocumentType.income,
          why: 'Family income must be below ₹8 lakh to qualify.',
        ),
        DocumentRequirement(
          type: DocumentType.bankPassbook,
          why: 'Scholarship amount is credited to this account.',
        ),
      ],
      process: const [
        ServiceStep(
          'Check eligibility',
          'Confirm category, income and course rules on the portal.',
        ),
        ServiceStep(
          'Register on the portal',
          'Create an account with Aadhaar and mobile number.',
        ),
        ServiceStep(
          'Fill the application',
          'Enter institute, course and bank details carefully.',
        ),
        ServiceStep(
          'Upload documents',
          'Attach the verified documents SevaSetu prepared for you.',
        ),
        ServiceStep(
          'Submit to institute',
          'Your institute must verify and forward the application.',
        ),
      ],
      importantDates: [
        ImportantDate('Application window', '01 Oct – 30 Nov $ay'),
        ImportantDate('Institute verification', 'Within 15 days of submit'),
        ImportantDate('First instalment', 'Jan – Feb ${ay + 1}'),
      ],
      applicationMode: 'Online',
      applyPortal: 'National Scholarship Portal — scholarships.gov.in',
      helpline: '1800-111-888',
      officialUrl: 'https://scholarships.gov.in',
      lastDateNote: 'Applications close 30 Nov $ay — prepare documents now.',
      eligibility: [
        _rule(
          'Permanent resident of Maharashtra',
          30,
          'Domicile certificate of Maharashtra required.',
          (p, _) => p.state == 'Maharashtra',
        ),
        _rule(
          'Enrolled in a post-matric course (Class 11 to PG)',
          30,
          'Must be currently enrolled after Class 10.',
          (p, _) => p.isStudent && p.education != EducationLevel.secondary,
        ),
        _rule(
          'Family annual income below ₹8,00,000',
          25,
          'Valid Income Certificate under ₹8 lakh needed.',
          (p, _) => p.annualIncomeLakhs < 8,
        ),
        _rule(
          'Belongs to OBC/SC/ST or minority category',
          25,
          'Category certificate required for the quota.',
          (p, _) => p.casteCategory != CasteCategory.general,
        ),
        _rule(
          'Valid Income Certificate on file',
          10,
          'Your Income Certificate has expired — upload a renewed one.',
          (p, vault) {
            final income =
                vault.where((d) => d.type == DocumentType.income).toList()
                  ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
            return income.isNotEmpty && income.first.isValidNow;
          },
        ),
      ],
    ),
    GovService(
      id: 'svc-pmay',
      name: 'PMAY Housing Assistance',
      shortDescription:
          'Central subsidy to help urban families own a pucca house under '
          'Pradhan Mantri Awas Yojana.',
      description:
          'PMAY (Urban) provides interest subsidy on home loans so that '
          'economically weaker and low-income families can afford a pucca '
          'house. The subsidy depends on family income and is released '
          'directly to the lending institution. SevaSetu lists the identity, '
          'address and income proofs you need before approaching a bank.',
      category: ServiceCategory.housing,
      department: 'Ministry of Housing & Urban Affairs',
      scope: 'All India',
      keywords: [
        'housing',
        'house',
        'home',
        'loan',
        'pma',
        'pradhan mantri awas',
        'ghar',
        'मकान',
        'आवास',
        'घर',
        'कर्ज',
        'subsidy',
      ],
      requiredDocuments: const [
        DocumentRequirement(
          type: DocumentType.aadhaar,
          why: 'Beneficiary identity on the PMAY portal.',
        ),
        DocumentRequirement(
          type: DocumentType.addressProof,
          why: 'Confirms the urban area where the house will be built.',
        ),
        DocumentRequirement(
          type: DocumentType.income,
          why: 'Income category decides the subsidy slab.',
        ),
        DocumentRequirement(
          type: DocumentType.bankPassbook,
          why: 'Loan account for subsidy credit.',
        ),
        DocumentRequirement(
          type: DocumentType.domicile,
          why: 'Optional proof of long-term residence in the state.',
        ),
      ],
      process: const [
        ServiceStep(
          'Check income slab',
          'EWS < ₹3L, LIG ₹3–6L, MIG ₹6–18L per year.',
        ),
        ServiceStep(
          'Register on PMAY portal',
          'Submit Aadhaar-verified application with address.',
        ),
        ServiceStep(
          'Get subsidy approval',
          'Receive the benefit sanction letter.',
        ),
        ServiceStep(
          'Approach a bank',
          'Use the sanction to take a subsidised home loan.',
        ),
      ],
      importantDates: [
        ImportantDate(
          'Scheme validity',
          'Till 31 Dec ${t.year} (check portal)',
        ),
        ImportantDate('Sanction review', 'Quarterly (Mar / Jun / Sep / Dec)'),
      ],
      applicationMode: 'Online',
      applyPortal: 'pmay-urban.gov.in',
      helpline: '1800-11-6622',
      officialUrl: 'https://pmay-urban.gov.in',
      lastDateNote:
          'Scheme is open year-round — apply when documents are ready.',
      eligibility: [
        _rule('Age 18 or above', 30, '', (p, _) => p.age >= 18),
        _rule(
          'Family income below ₹6 lakh (LIG)',
          30,
          'For LIG slab the annual family income must be under ₹6 lakh.',
          (p, _) => p.annualIncomeLakhs < 6,
        ),
        _rule(
          'No pucca house owned by family',
          40,
          'Self-declaration of not owning a pucca house is mandatory.',
          (p, _) => false, // declaration pending in demo persona
        ),
      ],
    ),
    GovService(
      id: 'svc-farmer',
      name: 'Farmer Support Service',
      shortDescription:
          'State assistance for farmers: input subsidy, crop insurance '
          'enrolment and scheme guidance.',
      description:
          'Farmer Support bundles state-level help for cultivators — guidance '
          'on input subsidies, PM Fasal Bima crop insurance enrolment and '
          'updates on minimum support price procurement. SevaSetu prepares '
          'the land and identity documents commonly asked by the agriculture '
          'department.',
      category: ServiceCategory.agriculture,
      department: 'Agriculture Department, Maharashtra',
      scope: 'Maharashtra',
      keywords: [
        'farmer',
        'kisan',
        'crop',
        'insurance',
        'subsidy',
        'farming',
        'land',
        'किसान',
        'शेतकरी',
        'पीक',
        'विमा',
        'अनुदान',
        'खेती',
      ],
      requiredDocuments: const [
        DocumentRequirement(
          type: DocumentType.aadhaar,
          why: 'Identity for subsidy and insurance accounts.',
        ),
        DocumentRequirement(
          type: DocumentType.landRecord,
          why: '7/12 extract proves ownership of cultivable land.',
        ),
        DocumentRequirement(
          type: DocumentType.bankPassbook,
          why: 'Subsidies are credited directly to this account.',
        ),
        DocumentRequirement(
          type: DocumentType.addressProof,
          why: 'Village and taluka address for scheme records.',
        ),
      ],
      process: const [
        ServiceStep(
          'Visit your village agriculture assistant (Talathi)',
          'Collect updated 7/12 and land records.',
        ),
        ServiceStep(
          'Register on the agriculture portal',
          'Link Aadhaar and bank account.',
        ),
        ServiceStep(
          'Select the assistance needed',
          'Input subsidy, insurance or MSP guidance.',
        ),
        ServiceStep(
          'Track in your application',
          'SevaSetu keeps the status updated.',
        ),
      ],
      importantDates: [
        ImportantDate('Crop insurance window (Kharif)', 'Jun – Jul ${t.year}'),
        ImportantDate('Crop insurance window (Rabi)', 'Oct – Dec ${t.year}'),
      ],
      applicationMode: 'Both',
      applyPortal: 'Agriculture office / mahadbt.maharashtra.gov.in',
      helpline: '1800-233-4323',
      officialUrl: 'https://www.mahaagri.gov.in',
      lastDateNote: 'Insurance windows follow the sowing season.',
      eligibility: [
        _rule(
          'Practising farmer or cultivator',
          40,
          'Profile occupation should reflect farming.',
          (p, _) => p.occupation == Occupation.farmer,
        ),
        _rule(
          'Owns or leases cultivable land',
          30,
          'Updated 7/12 land record is required.',
          (p, vault) {
            final land = vault
                .where((d) => d.type == DocumentType.landRecord)
                .toList();
            return land.isNotEmpty && land.first.isValidNow;
          },
        ),
        _rule('Age 18 or above', 30, '', (p, _) => p.age >= 18),
      ],
    ),
    GovService(
      id: 'svc-employment',
      name: 'Employment Assistance',
      shortDescription:
          'Employment Exchange registration and job-seeker assistance for '
          'educated youth in Maharashtra.',
      description:
          'Registering with the Maharashtra Employment Exchange keeps you in '
          'the database government departments and companies screen for '
          'recruitment. SevaSetu guides you through registration and keeps '
          'your documents ready so you can register the moment you qualify.',
      category: ServiceCategory.employment,
      department: 'Employment & Self-Employment Dept., Maharashtra',
      scope: 'Maharashtra',
      keywords: [
        'job',
        'employment',
        'register',
        'career',
        'rojgar',
        'naukri',
        'नौकरी',
        'रोजगार',
        'भर्ती',
        'recruitment',
        'fresher',
      ],
      requiredDocuments: const [
        DocumentRequirement(
          type: DocumentType.aadhaar,
          why: 'Identity for the Employment Exchange database.',
        ),
        DocumentRequirement(
          type: DocumentType.photograph,
          why: 'Recent photograph for the registration card.',
        ),
        DocumentRequirement(
          type: DocumentType.marksheet,
          why: 'Educational qualification proof for job matching.',
        ),
        DocumentRequirement(
          type: DocumentType.bankPassbook,
          why: 'Bank details for future interview allowances.',
        ),
      ],
      process: const [
        ServiceStep(
          'Check qualification codes',
          'Map your education to the registration code.',
        ),
        ServiceStep(
          'Register online',
          'Verify Aadhaar and upload your photograph.',
        ),
        ServiceStep(
          'Receive registration number',
          'Keep the card for future applications.',
        ),
        ServiceStep(
          'Update regularly',
          'Renew registration to stay in the active list.',
        ),
      ],
      importantDates: [
        ImportantDate('Registration', 'Open throughout the year'),
        ImportantDate('Renewal', 'Every 3 years'),
      ],
      applicationMode: 'Online',
      applyPortal: 'rojgar.mahaswayam.gov.in',
      helpline: '1800-233-1401',
      officialUrl: 'https://rojgar.mahaswayam.gov.in',
      lastDateNote: 'Register once documents are verified for best results.',
      eligibility: [
        _rule(
          'Age between 18 and 35',
          30,
          '',
          (p, _) => p.age >= 18 && p.age <= 35,
        ),
        _rule(
          'Completed at least Class 10',
          25,
          'Minimum education required for registration.',
          (p, _) => p.education != EducationLevel.secondary || p.age >= 21,
        ),
        _rule(
          'Not in full-time employment',
          25,
          'Registration is for job-seekers.',
          (p, _) =>
              p.occupation == Occupation.student ||
              p.occupation == Occupation.unemployed ||
              p.occupation == Occupation.homemaker,
        ),
        _rule(
          'Aadhaar-linked active bank account',
          20,
          'Benefits are paid to the registered account.',
          (p, vault) {
            final bank = vault
                .where((d) => d.type == DocumentType.bankPassbook)
                .toList();
            return bank.isNotEmpty &&
                (bank.first.verified || bank.first.isValidNow);
          },
        ),
      ],
    ),
  ];
}

EligibilityRule _rule(
  String title,
  double weight,
  String failHint,
  bool Function(UserProfile, List<CitizenDocument>) check,
) {
  return EligibilityRule(
    title: title,
    weight: weight,
    check: check,
    failHint: failHint,
  );
}
