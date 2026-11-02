import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'features/account/presentation/pages/edit_profile_page.dart';
import 'features/activity_dial/presentation/pages/activity_dial_page.dart';
import 'features/activity_dial/presentation/pages/event_types_page.dart';
import 'features/friends/presentation/pages/add_qr_page.dart';
import 'features/friends/presentation/pages/friends_page.dart';
import 'features/onboarding/presentation/app_start_gate.dart';
import 'features/realtime/presentation/widgets/realtime_host.dart';
import 'features/shell/presentation/pages/main_shell_page.dart';
import 'features/widgets/presentation/pages/widget_selection_page.dart';

class ChamApp extends StatelessWidget {
  const ChamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chấm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFB53216),
        scaffoldBackgroundColor: const Color(0xFFFAF6F0),
        fontFamily: null,
      ),
      builder: (context, child) {
        final app = RealtimeHost(child: child ?? const SizedBox.shrink());
        return Env.isProd
            ? app
            : Banner(
                message: Env.appEnv.name.toUpperCase(),
                // Góc dưới trái: góc trên phải là nút hồ sơ / avatar.
                location: BannerLocation.bottomStart,
                child: app,
              );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const AppStartGate(),
        '/dial': (context) => const ActivityDialPage(),
        // Mở shell ở đúng màn, để Back trong shell vẫn quay về Trang chủ.
        '/feed': (context) => const MainShellPage(initialPane: ShellPane.feed),
        '/analytics': (context) => const MainShellPage(initialPane: ShellPane.analytics),
        '/history': (context) => const MainShellPage(initialPane: ShellPane.history),
        '/widgets': (context) => const WidgetSelectionPage(),
        '/add-qr': (context) => const AddQrPage(),
        '/event-types': (context) => const EventTypesPage(),
        '/friends': (context) => const FriendsPage(),
        '/profile': (context) => const EditProfilePage(),
      },
    );
  }
}
