import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'features/activity_dial/presentation/pages/activity_dial_page.dart';

class ChamApp extends StatelessWidget {
  const ChamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chấm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF694A),
        scaffoldBackgroundColor: const Color(0xFFFAF6F0),
        fontFamily: null,
      ),
      builder: (context, child) => Env.isProd
          ? child!
          : Banner(
              message: Env.appEnv.name.toUpperCase(),
              location: BannerLocation.topEnd,
              child: child,
            ),
      home: const ActivityDialPage(),
    );
  }
}

