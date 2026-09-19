import '../models/document.dart';
import '../models/profile.dart';
import '../models/service.dart';

/// Seed catalogue: authentic, real-world government schemes with personalised
/// eligibility rules, required documents and comprehensive application guidance.
List<GovService> buildSeedServices({DateTime? now}) {
  final t = now ?? DateTime.now();

  final ay = t.month >= 7 ? t.year + 1 : t.year; // application year label

  return [
    // -------------------------------------------------------------
    // 1. Post-Matric Scholarship (MahaDBT & NSP)
    // -------------------------------------------------------------
    GovService(
      id: 'svc-pms',
      name: 'Post-Matric Scholarship',
      shortDescription:
          'Financial assistance for SC/ST/OBC/EWS students pursuing higher '
          'education (Class 11, Diploma, Degree, PG).',
      description:
          'The Post-Matric Scholarship supports students from economically '
          'weaker families and reserved categories to pursue education after '
          'Class 10. Tuition and exam fees are reimbursed, and an annual maintenance '
          'allowance is credited directly to the student\'s Aadhaar-seeded bank '
          'account via DBT. SevaSetu helps you prepare all verified documents '
          'required by the MahaDBT and National Scholarship Portal before you apply.',
      category: ServiceCategory.education,
      department: 'Higher & Technical Education Dept., Maharashtra',
      scope: 'Maharashtra',
      keywords: [
        'scholarship',
        'student',
        'college',
        'fees',
        'education',
        'post matric',
        'mahadbt',
        'chhatravrutti',
        'शिष्यवृत्ती',
        'छात्रवृत्ति',
        'शिक्षण',
        'obc',
        'sc',
        'st',
        'ews',
      ],
      requiredDocuments: const [
        DocumentRequirement(
          type: DocumentType.aadhaar,
          why: 'Primary identity and mandatory DBT linkage on the scholarship portal.',
        ),
        DocumentRequirement(
          type: DocumentType.domicile,
          why: 'Proves 15-year Maharashtra residence for state scholarship quotas.',
        ),
        DocumentRequirement(
          type: DocumentType.marksheet,
          why: 'Previous-year marksheet proves continuing education and qualification.',
        ),
        DocumentRequirement(
          type: DocumentType.caste,
          why: 'Caste certificate is required for SC/ST/OBC/SBC/VJNT benefits.',
        ),
        DocumentRequirement(
          type: DocumentType.income,
          why: 'Family income certificate must certify annual income below ₹8 lakh.',
        ),
        DocumentRequirement(
          type: DocumentType.bankPassbook,
          why: 'Aadhaar-seeded savings account where scholarship allowance is disbursed.',
        ),
      ],
      process: const [
        ServiceStep(
          'Check Course & College Eligibility',
          'Confirm that your course and institute are approved on the MahaDBT portal.',
        ),
        ServiceStep(
          'Aadhaar Authentication',
          'Authenticate your account using Aadhaar OTP or biometric verification.',
        ),
        ServiceStep(
          'Fill Application & Select Scheme',
          'Select your department, course, hostel status, and enter academic details.',
        ),
        ServiceStep(
          'Upload Verified Documents',
          'Attach verified caste, income, domicile certificates, marksheets and fee receipts.',
        ),
        ServiceStep(
          'College Scrutiny & Forwarding',
          'Your college scrutiny officer verifies original documents within 15 days.',
        ),
        ServiceStep(
          'Direct Benefit Disbursement',
          'Approved fee reimbursement and maintenance allowance are credited via DBT.',
        ),
      ],
      importantDates: [
        ImportantDate('Application Window', '01 Aug – 31 Dec $ay'),
        ImportantDate('Institute Verification', 'Within 15 days of online submit'),
        ImportantDate('First Instalment (50%)', 'Jan – Feb ${ay + 1}'),
        ImportantDate('Second Instalment (50%)', 'Apr – May ${ay + 1}'),
      ],
      applicationMode: 'Online',
      applyPortal: 'MahaDBT Portal — mahadbt.maharashtra.gov.in / NSP scholarships.gov.in',
      helpline: '022-49150800',
      officialUrl: 'https://mahadbt.maharashtra.gov.in',
      lastDateNote: 'Applications close 31 Dec $ay — verify all documents before college scrutiny.',
      eligibility: [
        _rule(
          'Age between 16 and 35',
          20,
          'Student must be between 16 and 35 years of age.',
          (p, _) => p.age >= 16 && p.age <= 35,
        ),
        _rule(
          'Currently enrolled student',
          25,
          'Profile occupation must reflect student status.',
          (p, _) => p.isStudent,
        ),
        _rule(
          'Family income below ₹8 lakh',
          25,
          'Annual family income must be under ₹8 lakh for scholarship benefit.',
          (p, _) => p.annualIncomeLakhs <= 8.0,
        ),
        _rule(
          'Belongs to OBC / SC / ST / EWS category',
          30,
          'A valid caste or EWS certificate is required for quota.',
          (p, _) => p.casteCategory != CasteCategory.general,
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 2. Mukhyamantri Majhi Ladki Bahin Yojana
    // -------------------------------------------------------------
    GovService(
      id: 'svc-ladki-bahin',
      name: 'Mukhyamantri Majhi Ladki Bahin Yojana',
      shortDescription:
          'Monthly financial assistance of ₹1,500 for eligible women aged '
          '21–65 years in Maharashtra.',
      description:
          'Mukhyamantri Majhi Ladki Bahin Yojana provides ₹1,500 per month '
          'directly into the Aadhaar-linked bank account of eligible women in '
          'Maharashtra. The scheme aims to enhance financial independence, '
          'support maternal and nutritional health, and empower women across '
          'rural and urban households with annual family income under ₹2.5 lakh. '
          'SevaSetu helps women prepare all necessary identity, residence, and '
          'income proofs before applying.',
      category: ServiceCategory.women,
      department: 'Women & Child Development Department, Maharashtra',
      scope: 'Maharashtra',
      keywords: [
        'ladki bahin',
        'majhi ladki bahin',
        'women',
        'financial help',
        '1500',
        'mahila',
        'लाडकी बहीण',
        'माझी लाडकी बहीण',
        'महिला',
        'dbt',
        'nari shakti',
        'yojana',
        'aid',
      ],
      requiredDocuments: const [
        DocumentRequirement(
          type: DocumentType.aadhaar,
          why: 'Primary identity and mandatory Aadhaar OTP authentication.',
        ),
        DocumentRequirement(
          type: DocumentType.domicile,
          why: 'Proof of 15-year Maharashtra residence (Domicile certificate or Voter ID).',
        ),
        DocumentRequirement(
          type: DocumentType.income,
          why: 'Income certificate showing annual family income below ₹2.5 lakh (or Yellow/Orange Ration Card).',
        ),
        DocumentRequirement(
          type: DocumentType.bankPassbook,
          why: 'Individual active bank account seeded with Aadhaar (NPCI mapped for DBT).',
        ),
        DocumentRequirement(
          type: DocumentType.photograph,
          why: 'Recent passport-size photograph of the woman applicant.',
        ),
      ],
      process: const [
        ServiceStep(
          'Check Eligibility Criteria',
          'Applicant must be an adult woman aged 21–65 with annual family income under ₹2.5L.',
        ),
        ServiceStep(
          'OTP Registration on Portal / App',
          'Register on ladakibahin.maharashtra.gov.in or the Nari Shakti Doot mobile app with Aadhaar OTP.',
        ),
        ServiceStep(
          'Fill Beneficiary Application',
          'Enter personal demographic details, marital status, and bank account IFSC & number.',
        ),
        ServiceStep(
          'Upload Verified Proofs',
          'Attach verified Aadhaar, domicile certificate or ration card, income certificate, and passbook.',
        ),
        ServiceStep(
          'Submit e-Hamipatra (Self-Declaration)',
          'Submit self-declaration agreeing to scheme terms regarding non-taxpayer and vehicle status.',
        ),
        ServiceStep(
          'Field Scrutiny & Direct Benefit Transfer',
          'Verified by Anganwadi Sevika / Ward committee; monthly ₹1,500 credited via DBT.',
        ),
      ],
      importantDates: [
        ImportantDate('Application Window', 'Open throughout the year on portal & app'),
        ImportantDate('Monthly DBT Disbursement', '15th of every month (₹1,500/month)'),
        ImportantDate('Aadhaar-Bank Seeding', 'Must be active before first installment'),
      ],
      applicationMode: 'Online & Nari Shakti Doot App',
      applyPortal: 'ladakibahin.maharashtra.gov.in / Nari Shakti Doot App / Setu Kendra',
      helpline: '181 (Women Toll-Free Helpline)',
      officialUrl: 'https://ladakibahin.maharashtra.gov.in',
      lastDateNote: 'Ongoing scheme — ₹1,500 credited on the 15th of each month to Aadhaar-seeded accounts.',
      eligibility: [
        _rule(
          'Resident of Maharashtra',
          30,
          'Must be a permanent resident of Maharashtra with valid domicile proof.',
          (p, vault) {
            final dom = vault.where((d) => d.type == DocumentType.domicile).toList();
            return dom.isNotEmpty && dom.first.isValidNow;
          },
        ),
        _rule(
          'Age between 21 and 65 years',
          30,
          'Applicant must be an adult woman aged between 21 and 65 years.',
          (p, _) => p.age >= 21 && p.age <= 65,
        ),
        _rule(
          'Family income below ₹2.50 lakh',
          25,
          'Annual family income must not exceed ₹2.50 lakh.',
          (p, _) => p.annualIncomeLakhs <= 2.5,
        ),
        _rule(
          'Aadhaar-linked active bank account',
          15,
          'Active bank account with NPCI mapping is required for DBT payments.',
          (p, vault) {
            final bank = vault.where((d) => d.type == DocumentType.bankPassbook).toList();
            return bank.isNotEmpty && bank.first.isValidNow;
          },
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 3. Passport Application (Passport Seva - MEA)
    // -------------------------------------------------------------
    GovService(
      id: 'svc-passport',
      name: 'Passport Application (Tatkaal / Normal)',
      shortDescription:
          'Apply for a fresh Indian passport or renewal with online slot booking '
          'at your nearest Passport Seva Kendra (PSK).',
      description:
          'An Indian Passport is the sovereign travel document issued by the '
          'Ministry of External Affairs under the Passports Act, 1967. It certifies '
          'your identity and Indian citizenship internationally. SevaSetu assists '
          'you in assembling all verified proofs of identity, address, date of birth, '
          'and Non-ECR qualification before you submit online and visit your designated '
          'Passport Seva Kendra (PSK) or Post Office PSK (POPSK).',
      category: ServiceCategory.identity,
      department: 'Consular, Passport & Visa Division, Ministry of External Affairs',
      scope: 'All India',
      keywords: [
        'passport',
        'psk',
        'tatkaal',
        'mea',
        'foreign travel',
        'visa',
        'police verification',
        'travel',
        'पासपोर्ट',
        'विदेश',
        'यात्रा',
        'popsk',
      ],
      requiredDocuments: const [
        DocumentRequirement(
          type: DocumentType.aadhaar,
          why: 'Official Valid Document for identity and primary address proof.',
        ),
        DocumentRequirement(
          type: DocumentType.addressProof,
          why: 'Proof of present residential address (Utility bill, bank passbook, or rent agreement).',
        ),
        DocumentRequirement(
          type: DocumentType.marksheet,
          why: 'Class 10 marksheet proves Date of Birth and qualifies you for Non-ECR status.',
        ),
        DocumentRequirement(
          type: DocumentType.bankPassbook,
          why: 'Running bank account statement with photo for secondary address verification.',
        ),
        DocumentRequirement(
          type: DocumentType.photograph,
          why: 'Standard 4.5 x 3.5 cm white-background photo for records and minor files.',
        ),
      ],
      process: const [
        ServiceStep(
          'Register on Passport Seva Portal',
          'Create an account on passportindia.gov.in and select your jurisdiction RPO.',
        ),
        ServiceStep(
          'Fill Online Application Form',
          'Select Fresh Passport or Re-issue, booklet size (36 or 60 pages), and Normal or Tatkaal.',
        ),
        ServiceStep(
          'Pay Fee & Schedule PSK Appointment',
          'Pay application fee online and select an available time slot at your nearest PSK/POPSK.',
        ),
        ServiceStep(
          'Visit PSK on Appointment Date',
          'Carry all original documents with photocopies for biometric capture and counter verification.',
        ),
        ServiceStep(
          'Local Police Verification',
          'Local police station conducts address and criminal background check verification.',
        ),
        ServiceStep(
          'Passport Printing & Speed Post Delivery',
          'Printed passport is securely dispatched via India Post Speed Post with live SMS tracking.',
        ),
      ],
      importantDates: [
        ImportantDate('Daily Appointment Release', 'Mon–Fri at 12:00 PM / 01:00 PM'),
        ImportantDate('Normal Processing Timeline', '7 to 14 working days post police report'),
        ImportantDate('Tatkaal Processing Timeline', '1 to 3 working days post PSK visit'),
        ImportantDate('Passport Validity', '10 years for adults (5 years for minors)'),
      ],
      applicationMode: 'Online Portal + PSK In-person',
      applyPortal: 'Passport Seva Online — passportindia.gov.in / mPassport Seva App',
      helpline: '1800-258-1800 (National Citizen Call Centre)',
      officialUrl: 'https://www.passportindia.gov.in',
      lastDateNote: 'Appointments fill up quickly — verify all documents in SevaSetu before booking your slot.',
      eligibility: [
        _rule(
          'Citizen of India',
          40,
          'Must be a citizen of India with valid proof of identity and nationality.',
          (p, _) => true,
        ),
        _rule(
          'Age 18 or above (Adult Passport)',
          20,
          'Standard adult passport applies to citizens aged 18 years and above.',
          (p, _) => p.age >= 18,
        ),
        _rule(
          'Verified present address proof',
          20,
          'Valid residential proof is required for police station jurisdiction check.',
          (p, vault) {
            final addr = vault
                .where((d) => d.type == DocumentType.addressProof || d.type == DocumentType.domicile)
                .toList();
            return addr.isNotEmpty && addr.first.isValidNow;
          },
        ),
        _rule(
          'Date of birth & Non-ECR qualification',
          20,
          'Class 10 or higher qualification exempts applicant from Emigration Check (Non-ECR).',
          (p, _) => p.education != EducationLevel.secondary,
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 4. PM-KISAN & Namo Shetkari Yojana (Farmer Support)
    // -------------------------------------------------------------
    GovService(
      id: 'svc-farmer',
      name: 'PM-KISAN & Namo Shetkari Yojana',
      shortDescription:
          'Annual income support of ₹12,000 (₹6,000 Central + ₹6,000 Maharashtra) '
          'for landholding farmer families.',
      description:
          'A combined central and state income support scheme for agricultural '
          'cultivators. Eligible landholding farmers in Maharashtra receive '
          '₹12,000 annually in 3 equal instalments of ₹4,000 (₹2,000 Central PM-KISAN '
          '+ ₹2,000 Maharashtra Namo Shetkari Mahasanman Nidhi) transferred '
          'directly into their bank accounts via DBT. SevaSetu assists farmers '
          'in validating 7/12 land extracts, 8-A land holdings, and completing '
          'mandatory Aadhaar e-KYC.',
      category: ServiceCategory.agriculture,
      department: 'Dept. of Agriculture, Cooperation & Farmers Welfare',
      scope: 'Maharashtra & All India',
      keywords: [
        'pm kisan',
        'namo shetkari',
        'farmer',
        'kisan',
        'agriculture',
        'shetkari',
        '7/12',
        'land',
        'subsidy',
        'dbt',
        'किसान',
        'शेतकरी',
        'शेती',
        'अनुदान',
        'पीक',
        'samman nidhi',
      ],
      requiredDocuments: const [
        DocumentRequirement(
          type: DocumentType.aadhaar,
          why: 'Primary identity for biometric e-KYC and Direct Benefit Transfer.',
        ),
        DocumentRequirement(
          type: DocumentType.landRecord,
          why: 'Updated 7/12 (Satbara) extract & 8-A holding proof showing cultivable agricultural land.',
        ),
        DocumentRequirement(
          type: DocumentType.bankPassbook,
          why: 'Aadhaar-seeded bank account with active NPCI DBT mapping.',
        ),
        DocumentRequirement(
          type: DocumentType.addressProof,
          why: 'Village and Taluka residence proof corresponding to land records.',
        ),
      ],
      process: const [
        ServiceStep(
          'Check Land Records & e-KYC',
          'Ensure 7/12 land extract is registered in applicant\'s name and linked to Aadhaar.',
        ),
        ServiceStep(
          'Register on PM-KISAN Portal',
          'Go to pmkisan.gov.in -> "New Farmer Registration" and enter Aadhaar & mobile number.',
        ),
        ServiceStep(
          'Enter Land & Revenue Details',
          'Input Khata number, survey/dag number, sub-division, and cultivable land area.',
        ),
        ServiceStep(
          'Complete Biometric / OTP e-KYC',
          'Perform mandatory Aadhaar OTP e-KYC online or biometric verification at a CSC center.',
        ),
        ServiceStep(
          'Taluka & District Revenue Verification',
          'Revenue officer / Talathi confirms land ownership and physical cultivation.',
        ),
        ServiceStep(
          'Automatic Namo Shetkari Enrolment',
          'Maharashtra beneficiaries are automatically enrolled for the state\'s ₹6,000 top-up.',
        ),
      ],
      importantDates: [
        ImportantDate('Period 1 Instalment (Apr–Jul)', 'Credited by July (₹4,000 total)'),
        ImportantDate('Period 2 Instalment (Aug–Nov)', 'Credited by November (₹4,000 total)'),
        ImportantDate('Period 3 Instalment (Dec–Mar)', 'Credited by March (₹4,000 total)'),
        ImportantDate('Aadhaar e-KYC & Seeding', 'Open year-round on pmkisan.gov.in & CSCs'),
      ],
      applicationMode: 'Online & Common Service Centre (CSC)',
      applyPortal: 'pmkisan.gov.in / nsmny.mahait.org / Aaple Sarkar Seva Kendra',
      helpline: '1551 (Kisan Call Centre) / 1800-180-1551',
      officialUrl: 'https://pmkisan.gov.in',
      lastDateNote: 'Instalment cycles recur every 4 months. Complete Aadhaar e-KYC to avoid payment holds.',
      eligibility: [
        _rule(
          'Practising cultivator or farmer family',
          35,
          'Profile occupation should reflect farming.',
          (p, _) => p.occupation == Occupation.farmer,
        ),
        _rule(
          'Owns cultivable agricultural land',
          35,
          'Updated 7/12 Satbara land record is mandatory.',
          (p, vault) {
            final land = vault.where((d) => d.type == DocumentType.landRecord).toList();
            return land.isNotEmpty && land.first.isValidNow;
          },
        ),
        _rule(
          'Aadhaar-seeded DBT bank account',
          15,
          'DBT payments require active Aadhaar bank linkage.',
          (p, vault) {
            final bank = vault.where((d) => d.type == DocumentType.bankPassbook).toList();
            return bank.isNotEmpty && bank.first.isValidNow;
          },
        ),
        _rule('Age 18 or above', 15, 'Farmer applicant must be an adult.', (p, _) => p.age >= 18),
      ],
    ),

    // -------------------------------------------------------------
    // 5. Pradhan Mantri Jan Dhan Yojana (PMJDY) Bank Account
    // -------------------------------------------------------------
    GovService(
      id: 'svc-bank-account',
      name: 'PM Jan Dhan Zero-Balance Bank Account',
      shortDescription:
          'Open a zero-balance basic savings bank account with free RuPay '
          'debit card, ₹2 lakh accident cover & overdraft.',
      description:
          'Pradhan Mantri Jan-Dhan Yojana (PMJDY) is the national mission for '
          'financial inclusion ensuring affordable access to banking, savings, '
          'and credit. Accounts have zero minimum balance requirements, earn interest, '
          'and come with a free RuPay debit card featuring ₹2 lakh accidental insurance '
          'coverage and an overdraft facility of up to ₹10,000. Having a PMJDY account '
          'is essential for receiving DBT payments for all government schemes.',
      category: ServiceCategory.financial,
      department: 'Department of Financial Services, Ministry of Finance',
      scope: 'All India',
      keywords: [
        'bank',
        'account',
        'jan dhan',
        'pmjdy',
        'zero balance',
        'rupay card',
        'savings',
        'dbt',
        'bank passbook',
        'खाते',
        'बँक',
        'जन धन',
        'बचत खाता',
        'overdraft',
      ],
      requiredDocuments: const [
        DocumentRequirement(
          type: DocumentType.aadhaar,
          why: 'Officially Valid Document (OVD) for instant paperless biometric e-KYC.',
        ),
        DocumentRequirement(
          type: DocumentType.addressProof,
          why: 'Proof of present residential address if current address differs from Aadhaar.',
        ),
        DocumentRequirement(
          type: DocumentType.photograph,
          why: 'Two passport-size colour photographs for bank account opening form.',
        ),
        DocumentRequirement(
          type: DocumentType.domicile,
          why: 'Secondary verification and state residence proof.',
        ),
      ],
      process: const [
        ServiceStep(
          'Locate Bank Branch or Bank Mitra',
          'Visit any nationalized or private commercial bank branch or local Bank Mitra (BC) point.',
        ),
        ServiceStep(
          'Fill Account Opening Form',
          'Provide personal details, nominee appointment, and existing identification information.',
        ),
        ServiceStep(
          'Aadhaar Biometric e-KYC',
          'Scan fingerprint or Iris for instant e-KYC verification without physical paperwork.',
        ),
        ServiceStep(
          'DBT Account Seeding Consent',
          'Sign consent to link the new account to the NPCI mapper for receiving government DBT funds.',
        ),
        ServiceStep(
          'Receive Passbook & RuPay Debit Card',
          'Collect your printed bank passbook with account number and your personalized RuPay debit card.',
        ),
      ],
      importantDates: [
        ImportantDate('Account Opening Window', 'Open throughout the year on any working banking day'),
        ImportantDate('Instant e-KYC Activation', 'Account active within 24 to 48 hours'),
        ImportantDate('Overdraft Facility (₹10k)', 'Available after 6 months of satisfactory operation'),
        ImportantDate('Accident Insurance Claim', 'RuPay card must be used at least once in last 90 days'),
      ],
      applicationMode: 'In-person Bank Branch / Bank Mitra / Video KYC',
      applyPortal: 'pmjdy.gov.in / Any Bank Branch / Doorstep Banking',
      helpline: '1800-180-1111 / 1800-11-0001 (National Toll-Free)',
      officialUrl: 'https://pmjdy.gov.in',
      lastDateNote: 'Permanent national financial inclusion mission — open your account at any bank anytime.',
      eligibility: [
        _rule(
          'Indian citizen aged 10 years or above',
          40,
          'Any Indian citizen aged 10 years or older is eligible to open an account.',
          (p, _) => p.age >= 10,
        ),
        _rule(
          'Aadhaar card available for e-KYC',
          30,
          'Aadhaar enables instant, paperless single-document account setup.',
          (p, vault) {
            final aadh = vault.where((d) => d.type == DocumentType.aadhaar).toList();
            return aadh.isNotEmpty && aadh.first.isValidNow;
          },
        ),
        _rule(
          'Passport photographs ready',
          15,
          'Passport-size photographs required for bank records.',
          (p, vault) {
            final photo = vault.where((d) => d.type == DocumentType.photograph).toList();
            return photo.isNotEmpty;
          },
        ),
        _rule(
          'No other basic savings account',
          15,
          'Applicant should not hold another active BSBDA account in the same bank.',
          (p, _) => true,
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
