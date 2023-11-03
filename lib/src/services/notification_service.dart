import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ignore: depend_on_referenced_packages
import 'package:timezone/data/latest_all.dart' as tz;
// ignore: depend_on_referenced_packages
import 'package:timezone/timezone.dart' as tz;

enum NotificationState {
  foreground,
  background,
  terminated
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  // static final messaging = FirebaseMessaging.instance;
  

  static initNotification() async {
    //Get the fcm Token
    getFcmToken();
    //Request Notification permission
    requestNotificationPermission();
    //Initialize notification settings
    initializeNotification();
  }

  //Initialize Local Notification
  static initializeNotification() async{
    //For Android Settings
    var initializationSettingsAndroid = const AndroidInitializationSettings('notification_icon');

    //For Ios Settings
    var initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:(int id, String? title, String? body, String? payload) async {
        if(payload != null){
          //Show a dialog, Do smthng
        }
      }
    );

    //Initialize Notification settings
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:(NotificationResponse details) async {
        if(details.payload !=null && details.payload != ""){
          routeFromNotification(NotificationState.foreground, details.payload);
        }
      }
    );
  }

  //Ask for notification permission
  static requestNotificationPermission() async {
    //For Android Permission
    if(Platform.isAndroid){
      await notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.requestNotificationsPermission();
      // NotificationSettings settings = await messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );
      // debugPrint(settings.authorizationStatus.toString());
    }

    // //For IOS permission
    if(Platform.isIOS){
      await notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()!.requestPermissions();
      // NotificationSettings settingsIos = await messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );
      // debugPrint(settingsIos.authorizationStatus.toString());
    }
  }

  //Get Fcm Token
  static getFcmToken() async{
    // String? fcm = await messaging.getToken();
    // debugPrint("fcm -> $fcm");
    // return fcm;
  }

  //Notification Details
  static notificationDetails(){
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'eyeportal', //Channel Id
        'eyeportal', //Channel name
        importance: Importance.high
      ),
      iOS: DarwinNotificationDetails()
    );
  }

  //Show Notification
  static showNotification({message}) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/1000;
      await notificationsPlugin.show(
        id,
        message.notification!.title ?? "", 
        message.notification!.body ?? "", 
        notificationDetails(),
        payload: jsonEncode(message.data)
      );
      //Initialize Settings, required to detect on tap on ios
      initializeNotification();

    } catch (e){
      debugPrint(e.toString());
    }
  }

  //Detect and Get Push Notification
  static getPushedNotification(context){
    // //On App Terminated
    // messaging.getInitialMessage().then((message){
    //   if(message != null ){
    //     //Route on App Terminated
    //     routeFromNotification(NotificationState.terminated, jsonEncode(message.data));
    //   }
    // });

    // //On Foreground Message
    // FirebaseMessaging.onMessage.listen((message) {
    //   debugPrint(message.data["payload"].toString());
    //   showNotification(
    //     message: message
    //   );
    // });

    // //On Backgorund Message
    // FirebaseMessaging.onMessageOpenedApp.listen((message) {
    //   routeFromNotification(NotificationState.background, jsonEncode(message.data));
    // });
  }

  // Create Channel
  Future<void> createChannel({String? id, String? name, String? desc}) async {

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      id ?? "", // Channel ID
      name ?? "", // Channel Name
      description: desc ?? "", // Channel Description
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      sound: const RawResourceAndroidNotificationSound('default'),
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  //Shedule Notification
  Future scheduleNotification(
      {int id = 0,
      String? title,
      String? body,
      String? payLoad,
      required DateTime scheduledNotificationDateTime
      }
  ) {
    tz.initializeTimeZones();
    return notificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    // scheduledNotificationDateTime as tz.TZDateTime,
    tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
    notificationDetails(),
    androidScheduleMode: AndroidScheduleMode.exact,
    // androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:UILocalNotificationDateInterpretation.absoluteTime);
  }


  //---------------------- Route From Notification ---------------------------------
  static routeFromNotification(NotificationState type, notificationData){
    // var messageData = jsonDecode(notificationData);
  }
}

