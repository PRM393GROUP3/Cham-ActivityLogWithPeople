import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'features/widgets/presentation/pages/widget_selection_page.dart';

class ChamApp extends StatelessWidget {
  const ChamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chăm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB53216),
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
        fontFamily: null,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFFB53216),
        brightness: Brightness.dark,
      ),
      builder: (context, child) => Env.isProd
          ? child!
          : Banner(
              message: Env.appEnv.name.toUpperCase(),
              location: BannerLocation.topEnd,
              child: child,
            ),
      home: const WidgetSelectionPage(),
    );
  }
}
