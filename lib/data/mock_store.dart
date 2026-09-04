import '../models/application.dart';
import '../models/document.dart';
import '../models/notification_item.dart';
import '../models/profile.dart';
import '../models/service.dart';
import '../utils/format.dart';
import 'seed_documents.dart';
import 'seed_services.dart';

/// In-memory "database" for the V1 prototype.
///
/// Every screen and service reads and mutates this store. Swapping to a
/// real backend later means moving these lists behind API calls while the
/// models and UI stay unchanged.
class AppDataStore {
  AppDataStore({DateTime? now}) {
    final t = now ?? DateTime.now();
    profile = const UserProfile(
      id: 'citizen-1',
      name: 'Arjun Deshmukh',
      age: 20,
      state: 'Maharashtra',
      district: 'Pune',
      occupation: Occupation.student,
      education: EducationLevel.undergrad,
      annualIncomeLakhs: 3.4,
      casteCategory: CasteCategory.obc,
      familySize: 4,
    );
    documents = buildSeedDocuments(now: t);
    services = buildSeedServices(now: t);
    applications = _seedApplications(t);
    notifications = _seedNotifications(t, documents);
  }

  UserProfile profile = const UserProfile(
    id: 'citizen-1',
    name: '',
    age: 0,
    state: '',
    district: '',
    occupation: Occupation.student,
    education: EducationLevel.undergrad,
    annualIncomeLakhs: 0,
    casteCategory: CasteCategory.general,
  );
  late List<CitizenDocument> documents;
  late List<GovService> services;
  late List<ServiceApplication> applications;
  late List<AppNotification> notifications;

  int _seq = 0;

  String nextId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';

  static List<ServiceApplication> _seedApplications(DateTime t) {
    final y = DateTime(t.year, t.month, t.day);
    DateTime days(int n) => y.subtract(Duration(days: n));
    return [
      ServiceApplication(
        id: 'app-pms-1',
        serviceId: 'svc-pms',
        serviceName: 'Post-Matric Scholarship',
        department: 'Higher & Technical Education Dept.',
        startedOn: days(6),
        currentPhase: ApplicationPhase.documentsPrepared,
        statusDetail: 'Documents 4 of 6 ready — 2 need attention.',
      ),
      ServiceApplication(
        id: 'app-emp-1',
        serviceId: 'svc-employment',
        serviceName: 'Employment Assistance',
        department: 'Employment & Self-Employment Dept.',
        startedOn: days(30),
        submittedOn: days(20),
        currentPhase: ApplicationPhase.underVerification,
        applicationNumber: 'MSDE/2026/88241',
        statusDetail: 'Verification by the Employment Exchange in progress.',
      ),
    ];
  }

  static List<AppNotification> _seedNotifications(
    DateTime t,
    List<CitizenDocument> vault,
  ) {
    DateTime ago(Duration d) => t.subtract(d);
    final income = vault.firstWhere((d) => d.type == DocumentType.income);
    final caste = vault.firstWhere((d) => d.type == DocumentType.caste);
    return [
      AppNotification(
        id: 'notif-1',
        kind: NotificationKind.document,
        title: 'Income Certificate expired',
        body:
            'Your Income Certificate expired on ${Formatters.date(income.expiresAt!)}. '
            'Renew it to complete the Post-Matric Scholarship documents.',
        at: ago(const Duration(hours: 2)),
        serviceId: 'svc-pms',
      ),
      AppNotification(
        id: 'notif-2',
        kind: NotificationKind.document,
        title: 'Caste Certificate expiring soon',
        body:
            'Your Caste Certificate ${Formatters.expiryPhrase(caste.expiresAt!, includeDate: true)}.',
        at: ago(const Duration(hours: 9)),
        serviceId: 'svc-pms',
      ),
      AppNotification(
        id: 'notif-3',
        kind: NotificationKind.journey,
        title: '2 documents need attention',
        body:
            'Your Post-Matric Scholarship journey needs 2 documents before you can apply.',
        at: ago(const Duration(hours: 26)),
        serviceId: 'svc-pms',
      ),
      AppNotification(
        id: 'notif-4',
        kind: NotificationKind.application,
        title: 'Application under verification',
        body:
            'Your Employment Assistance application (MSDE/2026/88241) is being verified.',
        at: ago(const Duration(days: 2)),
        serviceId: 'svc-employment',
      ),
      AppNotification(
        id: 'notif-5',
        kind: NotificationKind.tip,
        title: 'Welcome to SevaSetu',
        body:
            'Keep your profile updated so service and document suggestions stay relevant.',
        at: ago(const Duration(days: 6)),
      ),
    ];
  }
}
