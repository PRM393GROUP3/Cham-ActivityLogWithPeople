import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/presentation/pages/main_shell_page.dart';
import '../data/onboarding_storage.dart';
import 'pages/onboarding_page.dart';

/// Màn đầu tiên của app: màn chào ở lần mở đầu tiên, sau đó là màn hình chính.
class AppStartGate extends ConsumerStatefulWidget {
  const AppStartGate({super.key});

  @override
  ConsumerState<AppStartGate> createState() => _AppStartGateState();
}

class _AppStartGateState extends ConsumerState<AppStartGate> {
  late final Future<bool> _done = ref.read(onboardingStorageProvider).isDone();
  bool _finishedNow = false;

  Future<void> _finish() async {
    await ref.read(onboardingStorageProvider).markDone();
    if (mounted) setState(() => _finishedNow = true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _done,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(backgroundColor: Color(0xFFFAF6F0));
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: snapshot.data! || _finishedNow ? const MainShellPage() : OnboardingPage(onDone: _finish),
        );
      },
    );
  }
}
