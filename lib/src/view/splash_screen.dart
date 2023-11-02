import 'package:adv_call/src/view/wifi_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant/constants.dart';
import '../utils/shared_pref.dart';

class SlpashScreen extends StatefulWidget {
  const SlpashScreen({super.key});

  @override
  State<SlpashScreen> createState() => _SlpashScreenState();
}

class _SlpashScreenState extends State<SlpashScreen> {
  @override
  void initState() {
    super.initState();
    storeOpenState();
    // Navigate to the login screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () async{
      await SharedPref.write(AppConstant.justOpenedAppKey, true);
      Get.offAll(()=> const WifiScreen()
      // const HomePage()
      );
    });
  }

  // Store Open State
  Future<void> storeOpenState() async {
    await SharedPref.write(AppConstant.justOpenedAppKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: FlutterLogo(size: 200),
      ),
    );
  }
}