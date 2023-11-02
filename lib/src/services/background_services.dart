import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:adv_call/src/constant/constants.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  /// OPTIONAL, using custom notification channel id
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin.initialize(InitializationSettings(
      android: const AndroidInitializationSettings('ic_launcher'), 
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:(int id, String? title, String? body, String? payload) async {}
        )
      ),
      onDidReceiveNotificationResponse:(NotificationResponse notificationResponse) async {});
  }

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  //To Configure Bg Service(Required)
  await AppConstant.service.configure(
    //For Android
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Background Service',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),

    //For IOS
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: false,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );

  // service.startService();
}

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // SharedPreferences preferences = await SharedPreferences.getInstance();
  // await preferences.reload();
  // final log = preferences.getStringList('log') ?? <String>[];
  // log.add(DateTime.now().toIso8601String());
  // await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  /// OPTIONAL when use custom notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

  //Your Bg Task will be excuted here
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
        /// the notification id must be equals with AndroidConfiguration when you call configure() method.
        flutterLocalNotificationsPlugin.show(
          888,
          'Backgorund Service',
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

        //Show notification
        // if(read("scheduledTime") != null && read("scheduledTime") != ""){
        //   tz.initializeTimeZones();
        //   NotificationService().scheduleNotification(
        //     title: 'Scheduled Notification',
        //     body: '${read("scheduledTime")}',
        //     scheduledNotificationDateTime: DateTime.parse(read("scheduledTime")),
        //   );
        //   // .whenComplete(() {
        //   //   write("scheduledTime", "");
        //   //   // service.stopSelf();
        //   // });
        // }

        // if you don't using custom notification, uncomment this
        // service.setForegroundNotificationInfo(
        //   title: "My App Service",
        //   content: "Updated at ${DateTime.now()}",
        // );
      }

      flutterLocalNotificationsPlugin.show(
          888,
          'Backgorund Service',
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
    }

    /// you can see this log in logcat
    debugPrint('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": Platform.isAndroid ? "Android" : "IOS",
      },
    );
  });
}