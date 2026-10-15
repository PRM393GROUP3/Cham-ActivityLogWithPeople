import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'features/social/presentation/pages/feed_page.dart';

class ChamApp extends StatelessWidget {
  const ChamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cham',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5B58EB),
        useMaterial3: true,
      ),
      builder: (context, child) => Env.isProd
          ? (child ?? const SizedBox.shrink())
          : Banner(
              message: Env.appEnv.name.toUpperCase(),
              location: BannerLocation.topEnd,
              child: child ?? const SizedBox.shrink(),
            ),
      home: const FeedPage(),
    );
  }
}
