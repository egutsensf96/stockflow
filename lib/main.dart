import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockflow/screens/splash_screen.dart';

import 'config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: NexusApp())); // ✅ Riverpod root
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Inventory',
      debugShowCheckedModeBanner: false,
      theme: AppConfig.darkTheme,
      home: const SplashScreen(),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppConfig.darkTheme.colorScheme.primary.withOpacity(0.05),
                Colors.transparent,
              ],
              radius: 1.2,
              center: Alignment.topLeft,
            ),
          ),
          child: child,
        );
      },
    );
  }
}
