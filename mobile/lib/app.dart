import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'features/todos/presentation/pages/todo_page.dart';

class ChamApp extends StatelessWidget {
  const ChamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cham',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
      builder: (context, child) => Env.isProd
          ? child!
          : Banner(
              message: Env.appEnv.name.toUpperCase(),
              location: BannerLocation.topEnd,
              child: child,
            ),
      home: const TodoPage(),
    );
  }
}
