import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevasetu/main.dart';
import 'package:sevasetu/models/document.dart';
import 'package:sevasetu/screens/assistant_screen.dart';
import 'package:sevasetu/screens/service_details_screen.dart';
import 'package:sevasetu/screens/services_screen.dart';
import 'package:sevasetu/state/app_scope.dart';
import 'package:sevasetu/state/app_state.dart';
import 'package:sevasetu/utils/zip_writer.dart';

void main() {
  // ---- Shared helper: land on the home shell ----
  Future<void> startApp(WidgetTester tester) async {
    await tester.pumpWidget(const SevaSetuApp());
    await tester.pump(const Duration(seconds: 2, milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Skip'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('splash → onboarding → home navigation works', (tester) async {
    await startApp(tester);

    // Splash brand + tagline were shown before skipping onboarding.
    expect(
      find.textContaining('How can SevaSetu help you today?'),
      findsOneWidget,
    );
    expect(find.textContaining('Application Readiness'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Applications'), findsOneWidget);
    expect(find.text('My Journey'), findsOneWidget);
  });

  testWidgets('all five tabs render their surfaces', (tester) async {
    await startApp(tester);

    await tester.tap(find.text('Services'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Find a Government Service'), findsOneWidget);

    await tester.tap(find.text('My Journey'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Your guided path'), findsWidgets);
    expect(find.text('Documents being prepared'), findsWidgets);

    await tester.tap(find.text('Applications'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Track every application you have started.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Documents'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Your documents, organized and ready when you need them.'),
      findsOneWidget,
    );
  });

  testWidgets('service details surface document intelligence', (tester) async {
    await startApp(tester);

    await tester.tap(find.text('Services'));
    await tester.pump(const Duration(milliseconds: 400));

    final detailsRoute = find.byType(ServiceDetailsScreen);
    final tabServices = find.byType(ServicesTab);
    final firstService = find
        .descendant(
          of: tabServices,
          matching: find.text('Post-Matric Scholarship'),
        )
        .first;
    await tester.ensureVisible(firstService);
    await tester.tap(firstService);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(detailsRoute, findsOneWidget);
    final detailsScroll = find
        .descendant(of: detailsRoute, matching: find.byType(Scrollable))
        .first;

    await tester.scrollUntilVisible(
      find.text('Your Eligibility'),
      250,
      scrollable: detailsScroll,
    );
    expect(find.text('Your Eligibility'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Documents You Need'),
      250,
      scrollable: detailsScroll,
    );
    expect(find.text('Documents You Need'), findsOneWidget);
    expect(
      find.descendant(
        of: detailsRoute,
        matching: find.textContaining('documents ready'),
      ),
      findsWidgets,
    );
    await tester.scrollUntilVisible(
      find.text('Download Required Documents'),
      250,
      scrollable: detailsScroll,
    );
    expect(find.text('Download Required Documents'), findsOneWidget);
  });

  testWidgets('assistant replies with structured service cards', (
    tester,
  ) async {
    await startApp(tester);

    await tester.tap(find.text('SevaSetu AI'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final ctx = tester.element(find.byType(AssistantScreen));
    final appState = AppScope.of(ctx);
    expect(appState.chatMessages.length, 1); // welcome seed only
    expect(appState.chatMessages.first.fromUser, isFalse);

    final composer = find.descendant(
      of: find.byType(AssistantScreen),
      matching: find.byType(TextField),
    );
    await tester.enterText(composer, 'I want to apply for a scholarship');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(const Duration(milliseconds: 100));

    // Processing runs, then a structured reply is appended to the session.
    expect(appState.chatMessages.length, 2); // user bubble pushed
    expect(appState.chatMessages.last.fromUser, isTrue);
    for (var i = 0; i < 9; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
    await tester.pump(const Duration(milliseconds: 500));

    expect(appState.chatMessages.length, 3); // assistant reply appended
    final reply = appState.chatMessages.last;
    expect(reply.fromUser, isFalse);
    // ignore: avoid_print
    print('REPLY: ${reply.text}');
    expect(reply.text, contains('found'));
    expect(reply.serviceIds, isNotEmpty);

    // The reply is rendered in the conversation.
    expect(find.textContaining('found'), findsWidgets);
    expect(find.text('Check Eligibility'), findsWidgets);
  });

  test('readiness updates when a document is added', () async {
    final state = AppState();
    final service = state.serviceById('svc-pms');
    final before = state.readinessFor(service);
    expect(before.readyCount, 4);
    expect(before.requiredCount, 6);
    expect(before.percent, 67);
    // Income certificate is expired and the caste certificate is expiring.
    expect(before.expiredChecks.length, 1);
    expect(before.expiringChecks.length, 1);

    // Uploading the missing Income Certificate should lift readiness to 5/6.
    await state.uploadDocument(DocumentType.income, 'Camera');
    final after = state.readinessFor(service);
    expect(after.readyCount, 5);
    expect(after.percent, 83);
  });

  test('zip writer produces a structurally valid ZIP', () {
    final bytes = ZipWriter.write([
      ZipEntry('hello.txt', Uint8List.fromList('sevasetu'.codeUnits)),
      ZipEntry('nested/readme.txt', Uint8List.fromList('demo'.codeUnits)),
    ]);

    // Local file header + central directory + end-of-central-directory.
    expect(
      _indexOf(bytes, const [0x50, 0x4B, 0x03, 0x04]),
      greaterThanOrEqualTo(0),
    );
    expect(
      _indexOf(bytes, const [0x50, 0x4B, 0x01, 0x02]),
      greaterThanOrEqualTo(0),
    );
    expect(
      _indexOf(bytes, const [0x50, 0x4B, 0x05, 0x06]),
      greaterThanOrEqualTo(0),
    );

    // Stored entries keep their names readable in the archive.
    expect(_indexOf(bytes, 'hello.txt'.codeUnits), greaterThanOrEqualTo(0));
    expect(
      _indexOf(bytes, 'nested/readme.txt'.codeUnits),
      greaterThanOrEqualTo(0),
    );
  });
}

int _indexOf(List<int> haystack, List<int> needle) {
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return i;
  }
  return -1;
}
