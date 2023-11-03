import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:adv_call/src/constant/constants.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground
    ), 
    androidConfiguration: AndroidConfiguration(
      onStart: onStart, 
      isForegroundMode: true,
      autoStart: false,
      // notificationChannelId: "Advanced Call",
      // initialNotificationTitle: "Initializing Service",
      // initialNotificationContent: "The Service is starting..."
    )
  );
}

void onStart(ServiceInstance service){
  DartPluginRegistrant.ensureInitialized(); // Only available for flutter 3.0.0 and later
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(title: "Advance Call", content: "Service Running");

        // Handle headset events
        final headsetPlugin = HeadsetEvent();
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? storedNumber = prefs.getString(AppConstant.storedPhoneKey);
        headsetPlugin.setListener((val) async{
            debugPrint("Running");
            switch (val) {
              //On Headphone Connect
              case HeadsetState.CONNECT:
              (){};
              break;

              //On Headphone Disconnect
              case HeadsetState.DISCONNECT:
              AndroidIntent intent = AndroidIntent(
                action: 'android.intent.action.CALL',
                data: 'tel:${storedNumber ?? "9863021878"}',
              );
              await intent.launch();
              break;

              //On Headphone Next Button
              case HeadsetState.NEXT:
              AndroidIntent intent = AndroidIntent(
                action: 'android.intent.action.CALL',
                data: 'tel:${storedNumber ?? "9863021878"}',
              );
              await intent.launch();
              break;

              //On Headphone Previous Button
              case HeadsetState.PREV:
              AndroidIntent intent = AndroidIntent(
                action: 'android.intent.action.CALL',
                data: 'tel:${storedNumber ?? "9863021878"}',
              );
              await intent.launch();
              break;

              default:
            }
          }
        );
      }
    }

    debugPrint("BACKGROUND SERVICE IS RUNNING");
    service.invoke(
      "update",
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": Platform.isAndroid ? "Android" : "IOS",
      },
    );
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}