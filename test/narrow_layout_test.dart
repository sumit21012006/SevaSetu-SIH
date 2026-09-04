import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sevasetu/services/zip_service.dart';
import 'package:sevasetu/state/app_scope.dart';
import 'package:sevasetu/state/app_state.dart';
import 'package:sevasetu/theme/app_theme.dart';
import 'package:sevasetu/widgets/status_widgets.dart';
import 'package:sevasetu/widgets/zip_widgets.dart';

bool _realFontLoaded = false;

Future<void> _loadRealFont() async {
  const candidates = [
    'C:/Windows/Fonts/segoeui.ttf',
    'C:/Windows/Fonts/arial.ttf',
    '/System/Library/Fonts/Helvetica.ttc',
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

void main() {
  setUpAll(_loadRealFont);

  testWidgets('cards fit inside a 246px wide bubble', (tester) async {
    if (!_realFontLoaded) return;
    tester.view.physicalSize = const Size(1080, 2412);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late AppState state;
    await tester.pumpWidget(
      AppScope(
        state: state = AppState(),
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final svc = state.primaryService;
                final summary = state.readinessFor(svc);
                return ListView(
                  children: [
                    for (final doc in state.vaultDocuments)
                      _in(
                        246,
                        VaultDocumentCard(
                          document: doc,
                          onOpen: () {},
                          usageServices: const ['Post-Matric Scholarship'],
                        ),
                      ),
                    _in(
                      246,
                      ZipDownloadCard(
                        serviceName: svc.name,
                        summary: summary,
                        onDownload: () async => ZipPackResult(
                          fileName: 'x.zip',
                          filePath: '/tmp/x.zip',
                          sizeBytes: 4096,
                          includedFiles: const ['a.pdf'],
                          missingDocuments: const ['b.pdf'],
                          expiringDocuments: const ['c.pdf'],
                        ),
                        onViewMissing: () {},
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    // Scroll through the whole list to build every card.
    for (var i = 0; i < 12; i++) {
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -500),
        touchSlopY: 0,
      );
      await tester.pump(const Duration(milliseconds: 60));
    }
  });
}

Widget _in(double width, Widget child) {
  return SizedBox(
    width: width,
    child: Align(alignment: Alignment.topLeft, child: child),
  );
}
