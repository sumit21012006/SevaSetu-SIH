/// Central mapping of domain enums to icons/colours so widgets never
/// duplicate presentation decisions.
library;

import 'package:flutter/material.dart';

import '../models/application.dart';
import '../models/document.dart';
import '../models/journey.dart';
import '../models/notification_item.dart';
import '../models/service.dart';
import '../theme/app_colors.dart';

class StatusStyle {
  const StatusStyle(this.icon, this.color, this.background, this.l10nKey);
  final IconData icon;
  final Color color;
  final Color background;
  final String l10nKey;
}

StatusStyle statusStyle(DocStatus status) {
  switch (status) {
    case DocStatus.verified:
      return const StatusStyle(
        Icons.verified_rounded,
        AppColors.success,
        AppColors.successBg,
        'doc.verified',
      );
    case DocStatus.available:
      return const StatusStyle(
        Icons.check_circle_rounded,
        AppColors.secondary,
        Color(0xFFE3F4F1),
        'doc.available',
      );
    case DocStatus.verificationRequired:
      return const StatusStyle(
        Icons.fact_check_rounded,
        AppColors.warning,
        AppColors.warningBg,
        'doc.verificationRequired',
      );
    case DocStatus.expiringSoon:
      return const StatusStyle(
        Icons.schedule_rounded,
        AppColors.warning,
        AppColors.warningBg,
        'doc.expiringSoon',
      );
    case DocStatus.expired:
      return const StatusStyle(
        Icons.cancel_rounded,
        AppColors.danger,
        AppColors.dangerBg,
        'doc.expired',
      );
    case DocStatus.invalid:
      return const StatusStyle(
        Icons.gpp_bad_rounded,
        AppColors.danger,
        AppColors.dangerBg,
        'doc.invalid',
      );
    case DocStatus.missing:
      return const StatusStyle(
        Icons.remove_circle_outline_rounded,
        AppColors.danger,
        AppColors.dangerBg,
        'doc.missing',
      );
  }
}

/// Icon for a document type inside vault cards and tiles.
IconData documentTypeIcon(DocumentType type) {
  switch (type) {
    case DocumentType.aadhaar:
      return Icons.fingerprint_rounded;
    case DocumentType.domicile:
      return Icons.home_work_rounded;
    case DocumentType.income:
      return Icons.request_quote_rounded;
    case DocumentType.caste:
      return Icons.people_alt_rounded;
    case DocumentType.marksheet:
      return Icons.school_rounded;
    case DocumentType.bankPassbook:
      return Icons.account_balance_rounded;
    case DocumentType.photograph:
      return Icons.face_rounded;
    case DocumentType.addressProof:
      return Icons.location_city_rounded;
    case DocumentType.landRecord:
      return Icons.terrain_rounded;
  }
}

/// Icon for a document category.
IconData categoryIcon(DocumentCategory category) {
  switch (category) {
    case DocumentCategory.identity:
      return Icons.badge_rounded;
    case DocumentCategory.address:
      return Icons.home_rounded;
    case DocumentCategory.income:
      return Icons.receipt_long_rounded;
    case DocumentCategory.education:
      return Icons.menu_book_rounded;
    case DocumentCategory.financial:
      return Icons.payments_rounded;
    case DocumentCategory.photo:
      return Icons.photo_camera_rounded;
    case DocumentCategory.land:
      return Icons.landscape_rounded;
  }
}

/// Icon for a service category.
IconData serviceCategoryIcon(ServiceCategory category) {
  switch (category) {
    case ServiceCategory.education:
      return Icons.school_rounded;
    case ServiceCategory.housing:
      return Icons.home_rounded;
    case ServiceCategory.agriculture:
      return Icons.agriculture_rounded;
    case ServiceCategory.employment:
      return Icons.work_history_rounded;
    case ServiceCategory.other:
      return Icons.apps_rounded;
  }
}

/// Colour accent for a service category.
Color serviceCategoryColor(ServiceCategory category) {
  switch (category) {
    case ServiceCategory.education:
      return AppColors.primary;
    case ServiceCategory.housing:
      return AppColors.secondary;
    case ServiceCategory.agriculture:
      return const Color(0xFF2E7D32);
    case ServiceCategory.employment:
      return AppColors.aiPurple;
    case ServiceCategory.other:
      return AppColors.info;
  }
}

/// Colour accent for a document category.
Color categoryColor(DocumentCategory category) {
  switch (category) {
    case DocumentCategory.identity:
      return AppColors.primary;
    case DocumentCategory.address:
      return AppColors.secondary;
    case DocumentCategory.income:
      return AppColors.warning;
    case DocumentCategory.education:
      return AppColors.info;
    case DocumentCategory.financial:
      return const Color(0xFF7A5C1E);
    case DocumentCategory.photo:
      return AppColors.aiPurple;
    case DocumentCategory.land:
      return const Color(0xFF2E7D32);
  }
}

class JourneyPhaseUi {
  const JourneyPhaseUi(this.icon, this.label);
  final IconData icon;
  final String label;
}

JourneyPhaseUi journeyPhaseUi(PhaseId phase) {
  switch (phase) {
    case PhaseId.discover:
      return const JourneyPhaseUi(Icons.travel_explore_rounded, 'Discover');
    case PhaseId.eligibility:
      return const JourneyPhaseUi(Icons.rule_rounded, 'Eligibility');
    case PhaseId.documents:
      return const JourneyPhaseUi(Icons.folder_open_rounded, 'Documents');
    case PhaseId.verification:
      return const JourneyPhaseUi(Icons.verified_user_rounded, 'Verification');
    case PhaseId.guidance:
      return const JourneyPhaseUi(Icons.lightbulb_rounded, 'Guidance');
    case PhaseId.apply:
      return const JourneyPhaseUi(Icons.send_rounded, 'Apply');
    case PhaseId.track:
      return const JourneyPhaseUi(Icons.manage_search_rounded, 'Track');
  }
}

IconData notificationKindIcon(NotificationKind kind) {
  switch (kind) {
    case NotificationKind.document:
      return Icons.description_rounded;
    case NotificationKind.journey:
      return Icons.route_rounded;
    case NotificationKind.application:
      return Icons.feed_rounded;
    case NotificationKind.tip:
      return Icons.tips_and_updates_rounded;
  }
}

/// Ordering colours for application timeline phases.
class PhaseStyle {
  const PhaseStyle(this.icon, this.color);
  final IconData icon;
  final Color color;
}

PhaseStyle applicationPhaseUi(ApplicationPhase phase) {
  switch (phase) {
    case ApplicationPhase.serviceSelected:
      return const PhaseStyle(Icons.travel_explore_rounded, AppColors.primary);
    case ApplicationPhase.eligibilityChecked:
      return const PhaseStyle(Icons.rule_rounded, AppColors.info);
    case ApplicationPhase.documentsPrepared:
      return const PhaseStyle(Icons.folder_open_rounded, AppColors.secondary);
    case ApplicationPhase.applicationSubmitted:
      return const PhaseStyle(Icons.send_rounded, AppColors.aiPurple);
    case ApplicationPhase.underVerification:
      return const PhaseStyle(Icons.verified_user_rounded, AppColors.warning);
    case ApplicationPhase.approved:
      return const PhaseStyle(Icons.check_circle_rounded, AppColors.success);
    case ApplicationPhase.rejected:
      return const PhaseStyle(Icons.cancel_rounded, AppColors.danger);
  }
}
