import 'dart:async';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:http/http.dart' as http;
import '../constant/constants.dart';
import '../utils/shared_pref.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Device Info
  final deviceInfoPlugin = DeviceInfoPlugin();
  dynamic allDeviceInfo;
  String deviceId='';
  String deviceName='';

  //Socket client
  final serverUrl = 'http://192.168.1.8:3001';
  late Socket socket; // Define a Socket instance

  //Headset
  final headsetPlugin = HeadsetEvent();
  final numberCon = TextEditingController();
  late String savedNum;
  String text = "Stop Service";
  HeadsetState? _headsetState;
  bool popStatus = false;
  dynamic phoneNumber;

  @override
  void initState() {
    getDeviceInfo();//device info
    initilizeSocketClient();//Socket Setup
    initialize();
    super.initState(); 
  }

  initialize() async{
    checkForStoredNumber();
    checkHeadsetConnectionStatus();
  }

  //device info
  getDeviceInfo()async{
    final deviceInfo = await deviceInfoPlugin.deviceInfo;
    allDeviceInfo = deviceInfo.data;
    deviceId = allDeviceInfo["id"];
    deviceName = allDeviceInfo["device"];
    if(kDebugMode){
      print('device Id ====== $allDeviceInfo');
      print ('device Id ====== $deviceId');
    }
  }

  //Socket Setup
  initilizeSocketClient(){
    // Connect to the Socket.io server
    socket = io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.on('connect', (_) {
      if (kDebugMode) {
        print('Connected to the server');
      }
      // You can emit events here or handle other actions upon connection.
    });
    socket.connect();
  }

  //Send Data to Node Server from flutter socket client
  void _sendHttpRequestToServer(deviceStatus) async {
    // Create a JSON object with the message and device name
    final jsonData = {
      "deviceStatus": deviceStatus,
      "deviceName": deviceName,
      "deviceId": deviceId,
      "Datetime": DateTime.now(),
    };
    if (kDebugMode) {
      print(deviceStatus);
    }
    final url = Uri.parse('$serverUrl/api/v1/forecast?count=$jsonData');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('HTTP Request Success');
        print('Response data: ${response.body}');
      }
      // Handle the response as needed
    } else {
      if (kDebugMode) {
        print('HTTP Request Failed');
      }
    }
  }

  // Check for Headphone Status
  Future checkHeadsetConnectionStatus() async{
    headsetPlugin.requestPermission();
    var currentStatus = await headsetPlugin.getCurrentState;
    setState(() {
      _headsetState = currentStatus;
    });
    _sendHttpRequestToServer(currentStatus); 
    headsetPlugin.setListener((val) async{
      _headsetState = val;
      if(await SharedPref.read(AppConstant.justOpenedAppKey, defaultValue: "") == false){
        if(_headsetState == HeadsetState.DISCONNECT){
          callNumber();
        }
      }
      _sendHttpRequestToServer(val);  
      await SharedPref.write(AppConstant.justOpenedAppKey, false);
      setState(() {});
    });
  }

  // Check if a number is stored or not
  checkForStoredNumber() async{
    //Check if phone number is empty
    var checkNo = await getStoredNumber();
    if(checkNo == null || checkNo == ""){
      popStatus = false;
      showPopUp();
    } else{
      popStatus = true;
    }
    setState(() {});
  }

  @override
  void dispose() {
    numberCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 200,),
              //Headset Status
              Icon(
                Icons.headset,
                size: 35,
                color: _headsetState == HeadsetState.CONNECT
                    ? Colors.teal
                    : Colors.redAccent,
              ),
              const SizedBox(height: 10,),
              Text('State : ${_headsetState ?? "Not Connected"}\n', style: const TextStyle(fontSize: 16),),
              const SizedBox(height: 35,),
              ElevatedButton(
                child: const Text("Foreground Mode"),
                onPressed: () {
                  FlutterBackgroundService().invoke("setAsForeground");
                },
              ),
              const SizedBox(height: 20,),
              ElevatedButton(
                child: const Text("Background Mode"),
                onPressed: () {
                  FlutterBackgroundService().invoke("setAsBackground");
                },
              ),
              const SizedBox(height: 20,),
              //Stop App
              ElevatedButton(
                child: Text(text),
                onPressed: () async {
                  var isRunning = await AppConstant.service.isRunning();
                  if (isRunning) {
                    AppConstant.service.invoke("stopService");
                  } else {
                    AppConstant.service.startService();
                  }
      
                  if (!isRunning) {
                    text = 'Stop Service';
                  } else {
                    text = 'Start Service';
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 20,),
              // Change Number
              ElevatedButton(
                child: const Text("Change Number"),
                onPressed: (){
                  showPopUp();
                },
              ),
              const SizedBox(height: 20,),
              //Test Call
              ElevatedButton(
                child: const Text("Test Stored Number"),
                onPressed: (){
                  callNumber();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Store number
  Future<void> storeNumber(String number) async {
    await SharedPref.write(AppConstant.storedPhoneKey, number);
  }

  // Get Stored Number
  getStoredNumber() async {
    final String? storedNumber = await SharedPref.read(AppConstant.storedPhoneKey, defaultValue: "");
    return storedNumber;
  }

  //Call number
  callNumber() async{//set the number here
    var contact = await getStoredNumber();
    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:${contact ?? "9863021878"}',
    );
    await intent.launch();
  }

  //Show Pop Up
  showPopUp() async{
    var checkNumber = await getStoredNumber();
    if(checkNumber == null || checkNumber == ""){
      popStatus = false;
      // ignore: use_build_context_synchronously
      return showDialog(
        context: context,
        builder: (context){
          return WillPopScope(
            onWillPop: ()async => popStatus,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              title: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Enter a Contact that you want to call", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
                      const SizedBox(height: 20,),
                      Container(
                        height: 60,
                        width: 200,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          right: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(255, 223, 223, 223),
                              offset: Offset(0, 5),
                              blurRadius: 5
                            )
                          ]
                        ),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(15),
                            border: InputBorder.none,
                            labelText: "Enter a contact",
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val){
                            phoneNumber = val;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 20,),
                      //Save Contact to Shared prefrence
                      ElevatedButton(
                        onPressed: () {
                          if(phoneNumber != "" && phoneNumber!=null){
                            setState(() {
                              storeNumber(phoneNumber);
                              popStatus = true;
                            });
                            Navigator.pop(context);
                          } else{
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(milliseconds: 1000),
                                backgroundColor: Colors.red.withOpacity(0.9),
                                dismissDirection: DismissDirection.up,
                                margin: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).size.height - 100,
                                  right: 20,
                                  left: 20),
                                behavior: SnackBarBehavior.floating,
                                content: const Text("Please Enter a Contact First.", style: TextStyle(color: Colors.white),),
                              )
                            );
                          }
                        }, 
                        child: const Text("Save")
                      ),
                    ],
                  ),
                ),
              )
            ),
          );
        },
      );
    } else{
      popStatus = true;
      // ignore: use_build_context_synchronously
      return showDialog(
        context: context, 
        builder: (context){
          return WillPopScope(
            onWillPop: ()async => popStatus,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              title: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Enter a Contact that you want to call", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
                      const SizedBox(height: 20,),
                      Text("Prev Contact: ${checkNumber ?? "No Data"}", style: const TextStyle(fontSize: 12), textAlign: TextAlign.center,),
                      Container(
                        height: 60,
                        width: 200,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          right: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(255, 223, 223, 223),
                              offset: Offset(0, 5),
                              blurRadius: 5
                            )
                          ]
                        ),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(15),
                            border: InputBorder.none,
                            labelText: "Enter a contact",
                          ),
                          onChanged: (val){
                            phoneNumber = val;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 20,),
                      //Save Contact to Shared prefrence
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog<bool>(
                            context: context,
                            builder: (context) => WillPopScope(
                              onWillPop: () async=> false,
                              child: AlertDialog(
                                title: const Text("You will need to restart the App to change the contact."),
                                actions: [
                                  TextButton(
                                    onPressed: () async{
                                      var isRunning = await AppConstant.service.isRunning();
                                      if (isRunning) {
                                        AppConstant.service.invoke("stopService");
                                      } else {
                                        AppConstant.service.startService();
                                      }
                          
                                      if (!isRunning) {
                                        text = 'Stop Service';
                                      } else {
                                        text = 'Start Service';
                                      }
                                      //Save Number and pop
                                      if(phoneNumber != "" && phoneNumber!=null){
                                        setState(() {
                                          storeNumber(phoneNumber);
                                          popStatus = true;
                                        });
                                        SystemNavigator.pop();
                                      } else{
                                        setState(() {
                                          storeNumber(checkNumber);
                                          popStatus = true;
                                        });
                                        SystemNavigator.pop();
                                      }
                                    },
                                    child: const Text("OK")
                                  ),
                                ],
                              ),
                            )
                          );
                        }, 
                        child: const Text("Save")
                      ),
                    ],
                  ),
                ),
              )
            ),
          );
        },
      );
    }
  }
}