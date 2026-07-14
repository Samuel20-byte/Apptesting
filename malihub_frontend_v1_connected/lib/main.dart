import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService().init();
  runApp(const MalihubApp());
}

class MalihubApp extends StatelessWidget {
  const MalihubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malihub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
