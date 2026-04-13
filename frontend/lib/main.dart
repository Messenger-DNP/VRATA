import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: VrataApp()));
}

class VrataApp extends StatelessWidget {
  const VrataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VRATA',
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
