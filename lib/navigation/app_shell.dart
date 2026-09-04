import 'package:flutter/material.dart';

import '../screens/applications_screen.dart';
import '../screens/assistant_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/home_screen.dart';
import '../screens/journey_screen.dart';
import '../screens/services_screen.dart';
import '../state/app_scope.dart';
import '../widgets/action_widgets.dart';

/// Root shell: bottom navigation across the five primary surfaces plus the
/// persistent floating SevaSetu AI button.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _tabs = [
    HomeTab(),
    ServicesTab(),
    JourneyTab(),
    DocumentsTab(),
    ApplicationsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    String t(String k, [String f = '']) => state.tr(k, f);

    return Scaffold(
      body: IndexedStack(index: state.activeTabIndex, children: _tabs),
      floatingActionButton: AssistantFab(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AssistantScreen()),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.activeTabIndex,
        onDestinationSelected: state.goToTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: t('nav.home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: t('nav.services'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route_rounded),
            label: t('nav.journey'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder_rounded),
            label: t('nav.documents'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.feed_outlined),
            selectedIcon: const Icon(Icons.feed_rounded),
            label: t('nav.applications'),
          ),
        ],
      ),
    );
  }
}
