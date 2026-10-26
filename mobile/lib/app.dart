import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'features/account/presentation/pages/edit_profile_page.dart';
import 'features/activity_dial/presentation/pages/activity_dial_page.dart';
import 'features/activity_dial/presentation/pages/event_types_page.dart';
import 'features/friends/presentation/pages/add_qr_page.dart';
import 'features/friends/presentation/pages/friends_page.dart';
import 'features/shell/presentation/pages/main_shell_page.dart';
import 'features/social/presentation/pages/feed_page.dart';
import 'features/stats/presentation/pages/stats_page.dart';
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
      builder: (context, child) => Env.isProd
          ? (child ?? const SizedBox.shrink())
          : Banner(
              message: Env.appEnv.name.toUpperCase(),
              // Góc dưới trái: góc trên phải là nút hồ sơ / avatar.
              location: BannerLocation.bottomStart,
              child: child ?? const SizedBox.shrink(),
            ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainShellPage(),
        '/dial': (context) => const ActivityDialPage(),
        '/feed': (context) => const FeedPage(),
        '/widgets': (context) => const WidgetSelectionPage(),
        '/add-qr': (context) => const AddQrPage(),
        '/event-types': (context) => const EventTypesPage(),
        '/stats': (context) => const StatsPage(),
        '/friends': (context) => const FriendsPage(),
        '/profile': (context) => const EditProfilePage(),
      },
    );
  }
}
