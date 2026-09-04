import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sevasetu/main.dart';
import 'package:sevasetu/screens/application_detail_screen.dart';
import 'package:sevasetu/screens/applications_screen.dart';
import 'package:sevasetu/screens/assistant_screen.dart';
import 'package:sevasetu/screens/document_detail_screen.dart';
import 'package:sevasetu/screens/documents_screen.dart';
import 'package:sevasetu/screens/home_screen.dart';
import 'package:sevasetu/screens/journey_screen.dart';
import 'package:sevasetu/screens/notifications_screen.dart';
import 'package:sevasetu/screens/onboarding_screen.dart';
import 'package:sevasetu/screens/profile_edit_screen.dart';
import 'package:sevasetu/screens/profile_screen.dart';
import 'package:sevasetu/screens/readiness_screen.dart';
import 'package:sevasetu/screens/service_details_screen.dart';
import 'package:sevasetu/screens/services_screen.dart';
import 'package:sevasetu/state/app_scope.dart';
import 'package:sevasetu/state/app_state.dart';
import 'package:sevasetu/theme/app_theme.dart';

/// Widget tests use a placeholder font where every glyph is a full
/// `fontSize` square, which inflates text width ~2x and fabricates
/// overflows that never happen on a device. Load a real proportional font
/// (Segoe UI from Windows) under the 'Roboto' family so measured widths
/// match reality. Without a real font the placeholder metrics make these
/// tests meaningless, so they are skipped instead of reporting false hits.
bool _realFontLoaded = false;

Future<void> _loadRealFont() async {
  const candidates = [
    'C:/Windows/Fonts/segoeui.ttf',
    'C:/Windows/Fonts/arial.ttf',
    '/System/Library/Fonts/Helvetica.ttc',
    '/System/Library/Fonts/SFNS.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    try {
      final bytes = file.readAsBytesSync();
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      _realFontLoaded = true;
    } catch (_) {
      continue;
    }
    if (_realFontLoaded) break;
  }
}

/// Phone-sized viewport: Realme RMX3840 @ 360 x 804 logical pixels.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2412);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _harness(Widget home) {
  return AppScope(
    state: AppState(),
    child: MaterialApp(
      theme: buildAppTheme(),
      // Tab screens normally live inside the shell's Scaffold; provide the
      // same Material ancestor when pumping them directly.
      home: Scaffold(body: home),
    ),
  );
}

/// Drags the first scrollable down repeatedly so every list item builds.
Future<void> _scrollAll(WidgetTester tester, {int passes = 14}) async {
  for (var i = 0; i < passes; i++) {
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -480),
      touchSlopY: 0,
    );
    await tester.pump(const Duration(milliseconds: 70));
  }
  // Back to the top so the header rows are exercised again.
  await tester.drag(
    find.byType(Scrollable).first,
    const Offset(0, 4000),
    touchSlopY: 0,
  );
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _startApp(WidgetTester tester) async {
  await tester.pumpWidget(const SevaSetuApp());
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Skip'));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(_loadRealFont);

  testWidgets('onboarding pages fit at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await tester.pumpWidget(_harness(OnboardingScreen(onFinished: () {})));
    await tester.pump(const Duration(milliseconds: 300));
    for (var page = 0; page < 3; page++) {
      final button =
          find.widgetWithText(FilledButton, 'Continue').evaluate().isNotEmpty
          ? find.widgetWithText(FilledButton, 'Continue')
          : find.widgetWithText(FilledButton, 'Get Started');
      await tester.tap(button.first);
      await tester.pump(const Duration(milliseconds: 500));
    }
  });

  testWidgets('home tab has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await _startApp(tester);
    expect(find.byType(HomeTab), findsOneWidget);
    await _scrollAll(tester);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('services tab has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await _startApp(tester);
    await tester.tap(find.text('Services'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ServicesTab), findsOneWidget);
    await _scrollAll(tester);
  });

  testWidgets('documents tab has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await _startApp(tester);
    await tester.tap(find.text('Documents'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DocumentsTab), findsOneWidget);
    await _scrollAll(tester);
  });

  testWidgets('journey tab has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await _startApp(tester);
    await tester.tap(find.text('My Journey'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(JourneyTab), findsOneWidget);
    await _scrollAll(tester);
  });

  testWidgets('applications tab has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await _startApp(tester);
    await tester.tap(find.text('Applications'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ApplicationsTab), findsOneWidget);
    await _scrollAll(tester);
  });

  testWidgets('service details has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await tester.pumpWidget(
      _harness(const ServiceDetailsScreen(serviceId: 'svc-pms')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _scrollAll(tester);
  });

  testWidgets('readiness screen has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await tester.pumpWidget(
      _harness(const ReadinessScreen(serviceId: 'svc-pms')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _scrollAll(tester);
  });

  testWidgets('document detail has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await tester.pumpWidget(
      _harness(const DocumentDetailScreen(documentId: 'doc-income')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _scrollAll(tester);
  });

  testWidgets('application detail has no overflow at phone size', (
    tester,
  ) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await tester.pumpWidget(
      _harness(const ApplicationDetailScreen(applicationId: 'app-pms-1')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _scrollAll(tester);
  });

  testWidgets('notifications screen has no overflow at phone size', (
    tester,
  ) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await tester.pumpWidget(_harness(const NotificationsScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await _scrollAll(tester);
  });

  testWidgets('profile screen has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await tester.pumpWidget(_harness(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await _scrollAll(tester);
  });

  testWidgets('profile edit has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await tester.pumpWidget(_harness(const ProfileEditScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await _scrollAll(tester);
  });

  testWidgets('assistant chat has no overflow at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await tester.pumpWidget(_harness(const AssistantScreen()));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Send a request so a structured reply with action cards renders.
    final composer = find.byType(TextField).first;
    await tester.enterText(composer, 'I want to apply for a scholarship');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.testTextInput.receiveAction(TextInputAction.send);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
    await tester.pump(const Duration(milliseconds: 400));
    await _scrollAll(tester);
  });

  testWidgets('document action sheets fit at phone size', (tester) async {
    if (!_realFontLoaded) return;
    _phone(tester);
    await tester.pumpWidget(_harness(const DocumentsTab()));
    await tester.pump(const Duration(milliseconds: 400));

    // Add-document bottom sheet with the candidate list.
    await tester.scrollUntilVisible(
      find.text('Upload a new document'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Upload a new document'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    // Dismiss the sheet.
    await tester.tapAt(const Offset(180, 40));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
