import 'package:adv_call/src/widgets/snackbar_widget.dart';
import 'package:device_imei/device_imei.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_information/device_information.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:simnumber/sim_number.dart';
import 'package:simnumber/siminfo.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:http/http.dart' as http;
import 'package:unique_identifier/unique_identifier.dart';
import '../constant/constants.dart';
import '../utils/shared_pref.dart';
import '../view/home.dart';

class HomeController extends GetxController{
  TextEditingController serverUrlCon = TextEditingController();
  //Device Info
  dynamic deviceId        =''.obs;
  RxString deviceName     =''.obs;
  RxString platformVersion=''.obs;
  RxString imeiNo         =''.obs;
  RxString modelName      =''.obs;
  RxString manufacturer   =''.obs;
  RxString productName    =''.obs;
  RxString cpuType        =''.obs;
  RxString hardware       =''.obs;

  //wifi name
  RxString wifiname       =''.obs;
  RxString disconnectedWifiname = ''.obs;

  //Socket client
  late Socket socket; // Define a Socket instance
  RxBool isSocketServerConnected = false.obs;
  RxString receivedDataFromServer = ''.obs;

  //device info
  getDeviceInfo()async{
    try {
      platformVersion.value = await DeviceInformation.platformVersion;
      deviceName.value      = await DeviceInformation.deviceName;
      imeiNo.value          = await DeviceInformation.deviceIMEINumber;
      modelName.value       = await DeviceInformation.deviceModel;
      manufacturer.value    = await DeviceInformation.deviceManufacturer;
      productName.value     = await DeviceInformation.productName;
      cpuType.value         = await DeviceInformation.cpuName;
      String?  identifier = await UniqueIdentifier.serial;
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      var data = await deviceInfoPlugin.deviceInfo;
      String? imei = await DeviceImei().getDeviceImei();
      hardware.value        = await DeviceInformation.hardware;
    } on PlatformException {
      platformVersion.value = 'Failed to get platform version.';
    }
  }

  void printSimCardsData() async {
  try {
    SimInfo simInfo = await SimNumber.getSimData();
    for (var s in simInfo.cards) {
      print('-------------------Serial number: ${s.slotIndex} ${s.phoneNumber}');
    }
  } on Exception catch (e) {
    debugPrint("error! code: ${e.toString()} - message: ${e.toString()}");
  }
}

  //Connect To Socket Server
  connectToSocketServer(context, {bool isWifi = false}) async {
    final serverUrl = await getStoredSocketUrl();
    storeSocketUrl(serverUrl);
    // Connect to the Socket.io server
    socket = io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.off('connect');
    socket.on('connect', (_) {
      if (kDebugMode) {
        print('Connected to the server');
      }
      // You can emit events here or handle other actions upon connection.
      isSocketServerConnected.value = true;
      showSnackbar('Connected to server');
      if (isWifi) {
        sendWifiLogToServer(wifiname.value, disconnectedWifiname.value);
        Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage(),));
      }
    });
    socket.on('connect_error', (data) {
      if (kDebugMode) {
        print('Connection error: $data');
      }
      // Handle the connection error here.
      isSocketServerConnected.value = false;
      showSnackbar('Connection error: $data');
      socket.close();
    });
    // Handle incoming data
    socket.on('serverEvent', (data) {
      // Process the data as needed
      if (kDebugMode) {
        print("Received: $data");
      }
      receivedDataFromServer.value = data.toString();
    });
    socket.connect();
  }

  //Disconnect From Socket Server
  disconnectFromSocketServer(context){
    socket.off('disconnect');
    socket.on('disconnect',(_){
      if (kDebugMode) {
        print('Disconnected from the server');
      }
      isSocketServerConnected.value = false;
      receivedDataFromServer.value = '';
      showSnackbar('Disconnected from server');
    });
    socket.close();
  }
  
  // Store SocketServerUrl
  Future<void> storeSocketUrl(String url) async {
    await SharedPref.write(AppConstant.socketServerUrlKey, url);
  }

  // Get Stored Socket Url
  getStoredSocketUrl() async {
    final String? storedSocketUrl = await SharedPref.read(AppConstant.socketServerUrlKey, defaultValue: "");
    if(storedSocketUrl==null||storedSocketUrl==""){
      serverUrlCon.text='http://192.168.1.106:3001';
      return serverUrlCon.text;
    }
    else{
      serverUrlCon.text = storedSocketUrl;
      return serverUrlCon.text;
    }   
  }

  //Send Data to Node Server from flutter socket client
  void sendHttpRequestToServer(deviceStatus) async {
    if(isSocketServerConnected.value){
      String serverUrl = serverUrlCon.text.trim();
      // Create a JSON object with the message and device name
      final jsonData = {
        "deviceStatus": deviceStatus,
        "deviceName"  : deviceName,
        "imeiNo"      : imeiNo,
        "modelName"   : modelName,
        "manufacturer": manufacturer,
        "wifi name" : wifiname.value,
        "Datetime"    : DateTime.now(),
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
  }


  void sendWifiLogToServer(wifi, disconnectedWifi) async {
    if(isSocketServerConnected.value){
      String serverUrl = await getStoredSocketUrl(); 
      // serverUrlCon.text.trim();
      // Create a JSON object with the message and device name
      final jsonData = {
        "Wifi Connected To" : wifi,
        "Wifi Disconnected From" : disconnectedWifi,
        "deviceName"  : deviceName,
        "imeiNo"      : imeiNo,
        "modelName"   : modelName,
        "manufacturer": manufacturer,
        "Datetime"    : DateTime.now(),
      };
      if (kDebugMode) {
        print(wifi);
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
  }
}