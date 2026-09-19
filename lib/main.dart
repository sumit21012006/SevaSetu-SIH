import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/app_constants.dart';
import 'navigation/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Graceful fallback if .env is missing or unreadable
  }
  runApp(const SevaSetuApp());
}

class SevaSetuApp extends StatefulWidget {
  const SevaSetuApp({super.key});

  @override
  State<SevaSetuApp> createState() => _SevaSetuAppState();
}

class _SevaSetuAppState extends State<SevaSetuApp> {
  late final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: AppBrand.name,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const RootGate(),
      ),
    );
  }
}

/// Sequences splash → onboarding (first run) → app shell.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

enum _Stage { splash, onboarding, shell }

class _RootGateState extends State<RootGate> {
  _Stage _stage = _Stage.splash;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  void _startSplashTimer() {
    Future<void>.delayed(AppDurations.splash, () {
      if (!mounted) return;
      final state = AppScope.of(context);
      setState(() {
        _stage = state.hasSeenOnboarding ? _Stage.shell : _Stage.onboarding;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      child: switch (_stage) {
        _Stage.splash => const SplashView(key: ValueKey('splash')),
        _Stage.onboarding => OnboardingScreen(
          key: const ValueKey('onboarding'),
          onFinished: () {
            final state = AppScope.of(context);
            state.completeOnboarding();
            setState(() => _stage = _Stage.shell);
          },
        ),
        _Stage.shell => const AppShell(key: ValueKey('shell')),
      },
    );
  }
}
