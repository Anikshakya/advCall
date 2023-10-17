import 'package:adv_call/src/services/background_services.dart';
import 'package:adv_call/src/services/permission_services.dart';
import 'package:adv_call/src/view/home.dart';
import 'package:flutter/material.dart';

import 'src/utils/shared_pref.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundService.initializeService();
  await SharedPref.init();
  await PermissionManager.initializePermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Call',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage()
    );
  }
}
