import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:adv_call/src/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/shared_pref.dart';

class BackgroundService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initializeService() async {
    if (Platform.isIOS) {
      await _initializeIOSNotifications();
    }

    await _createNotificationChannel();
    await _configureBackgroundService();

    AppConstant.service.startService();
  }

  static Future<void> _initializeIOSNotifications() async {
    await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    ));
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground',
      'MY FOREGROUND SERVICE',
      description: 'This channel is used for important notifications.',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _configureBackgroundService() async {
    await AppConstant.service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: false,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Background Service',
        initialNotificationContent: 'Initializing',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Store if the app is just opened
    SharedPref.write(AppConstant.justOpenedAppKey, true);

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance && await service.isForegroundService()) {
        _handleForegroundService();
      }
    });
  }

  static void _handleForegroundService() async {
    // Your background task will be executed here
    // Show a custom notification
    flutterLocalNotificationsPlugin.show(
      888,
      'Background Service',
      'DateTime: ${DateTime.now()}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'my_foreground',
          'MY FOREGROUND SERVICE',
          icon: 'ic_launcher',
          ongoing: true,
        ),
      ),
    );

    // // Handle headset events
    // final headsetPlugin = HeadsetEvent();
    // await SharedPref.read(AppConstant.storedPhoneKey, defaultValue: "");
    // final SharedPreferences prefs = await SharedPreferences.getInstance();
    // final String? storedNumber = prefs.getString(AppConstant.storedPhoneKey);
    // if(await SharedPref.read(AppConstant.storedPhoneKey, defaultValue: "") == false){
    //   headsetPlugin.setListener((val) async {
    //     switch (val) {
    //       case HeadsetState.CONNECT:
    //         // On Headphone Connect
    //         () {};
    //         break;
    //       case HeadsetState.DISCONNECT:
    //         // On Headphone Disconnect
    //         AndroidIntent intent = AndroidIntent(
    //           action: 'android.intent.action.CALL',
    //           data: 'tel:${storedNumber ?? "9863021878"}',
    //         );
    //         await intent.launch();
    //         break;
    //       case HeadsetState.NEXT:
    //         // On Headphone Next Button
    //         AndroidIntent intent = AndroidIntent(
    //           action: 'android.intent.action.CALL',
    //           data: 'tel:${storedNumber ?? "9863021878"}',
    //         );
    //         await intent.launch();
    //         break;
    //       case HeadsetState.PREV:
    //         // On Headphone Previous Button
    //         AndroidIntent intent = AndroidIntent(
    //           action: 'android.intent.action.CALL',
    //           data: 'tel:${storedNumber ?? "9863021878"}',
    //         );
    //         await intent.launch();
    //         break;
    //       default:
    //     }
    //   });
    // }

    // Debugging log
    debugPrint('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    // Invoke method for updating the service with data
    final device = Platform.isAndroid ? 'Android' : 'IOS';
    AppConstant.service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  }
}