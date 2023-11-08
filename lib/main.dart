import 'package:adv_call/src/services/permission_services.dart';
import 'package:adv_call/src/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'src/utils/shared_pref.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPref.init();
  // await initializeService();
  await PermissionManager.initializePermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Advanced Call',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SlpashScreen()
    );
  }
}


// import 'package:flutter/material.dart';
// import 'dart:async';

// import 'package:flutter/services.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:sim_data/sim_data.dart';
// import 'package:sim_data/sim_model.dart' as sim;
// import 'package:simnumber/siminfo.dart';
// import 'package:simnumber/sim_number.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   SimInfo simInfo = SimInfo([]);
//   bool _isLoading = true;
//   SimData? _simData;
//   @override
//   void initState() {
//     super.initState();
//     SimNumber.listenPhonePermission((isPermissionGranted) {
//       print("isPermissionGranted : $isPermissionGranted");
//       if (isPermissionGranted) {
//         initPlatformState();
//       } else {}
//     });
//     initPlatformState();
//     init();
//   }

//   Future<void> init() async {
//     SimData simData;
//     try {
//       var status = await Permission.phone.status;
//       if (!status.isGranted) {
//         bool isGranted = await Permission.phone.request().isGranted;
//         if (!isGranted) return;
//       }
//       simData = await SimDataPlugin.getSimData();
//       setState(() {
//         _isLoading = false;
//         _simData = simData;
//       });
//       void printSimCardsData() async {
//         try {
//           SimData simData = await SimDataPlugin.getSimData();
//           for (var s in simData.cards) {
//             // ignore: avoid_print
//             print('Serial number: ${s.serialNumber}');
//           }
//         } on PlatformException catch (e) {
//           debugPrint("error! code: ${e.code} - message: ${e.message}");
//         }
//       }

//       printSimCardsData();
//     } catch (e) {
//       debugPrint(e.toString());
//       setState(() {
//         _isLoading = false;
//         _simData = null;
//       });
//     }
//   }
//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initPlatformState() async {
//     try {
//       simInfo = await SimNumber.getSimData();
//       setState(() {});
//     } on PlatformException {
//       print("simInfo  : " "2");
//     }
//     if (!mounted) return;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Plugin example app'),
//         ),
//         floatingActionButton: FloatingActionButton(
//           onPressed: (){
//             setState(() {
              
//             });
//           },
//           child: const Icon(Icons.refresh)
//         ),
//         body: Column(
//           children: [
//             simInfo.cards.isEmpty
//                 ? const Text("No SIM Card Found")
//                 : Padding(
//                     padding: const EdgeInsets.all(10),
//                     child: Column(
//                       children: simInfo.cards
//                           .map((e) => Row(
//                             children: [
//                               const Column(
//                                 children: [
//                                   Text("Slot"),
//                                   Text("Phone Number"),
//                                   Text("Carrier"),
//                                   Text("Name"),
//                                   Text("Country ISo"),
//                                 ],
//                               ),
//                               Column(
//                                 children: [
//                                   Text(e.slotIndex.toString()),
//                                   Text(e.phoneNumber.toString()),
//                                   Text(e.carrierName.toString()),
//                                   Text(e.displayName.toString()),
//                                   Text(e.countryIso.toString()),
//                                 ],
//                               ),
//                             ],
//                           ) )
//                           .toList(),
//                     ),
//                   ),
//            Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 children: _simData?.cards != null
//                     ? _simData!.cards.isEmpty
//                         ? [const Text('No sim card present')]
//                         : _simData!.cards
//                             .map(
//                               (sim.SimCard card) => ListTile(
//                                 leading: const Icon(Icons.sim_card),
//                                 title: Text('Card ${card.slotIndex}'),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: <Widget>[
//                                     Text('carrierName: ${card.carrierName}'),
//                                     Text('countryCode: ${card.countryCode}'),
//                                     Text('displayName: ${card.displayName}'),
//                                     Text(
//                                         'isDataRoaming: ${card.isDataRoaming}'),
//                                     Text(
//                                         'isNetworkRoaming: ${card.isNetworkRoaming}'),
//                                     Text('mcc: ${card.mcc}'),
//                                     Text('mnc: ${card.mnc}'),
//                                     Text('slotIndex: ${card.slotIndex}'),
//                                     Text('serialNumber: ${card.serialNumber}'),
//                                     Text(
//                                         'subscriptionId: ${card.subscriptionId}'),
//                                   ],
//                                 ),
//                               ),
//                             )
//                             .toList()
//                     : [
//                         Center(
//                           child: _isLoading
//                               ? const CircularProgressIndicator()
//                               : const Text('Failed to load data'),
//                         )
//                       ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }



// THis is mobile_number package

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:mobile_number/mobile_number.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   String _mobileNumber = '';
//   List<SimCard> _simCard = <SimCard>[];

//   @override
//   void initState() {
//     super.initState();
//     MobileNumber.listenPhonePermission((isPermissionGranted) {
//       if (isPermissionGranted) {
//         initMobileNumberState();
//       } else {}
//     });

//     initMobileNumberState();
//   }

//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initMobileNumberState() async {
//     if (!await MobileNumber.hasPhonePermission) {
//       await MobileNumber.requestPhonePermission;
//       return;
//     }
//     // Platform messages may fail, so we use a try/catch PlatformException.
//     try {
//       _mobileNumber = (await MobileNumber.mobileNumber)!;
//       _simCard = (await MobileNumber.getSimCards)!;
//     } on PlatformException catch (e) {
//       debugPrint("Failed to get mobile number because of '${e.message}'");
//     }

//     // If the widget was removed from the tree while the asynchronous platform
//     // message was in flight, we want to discard the reply rather than calling
//     // setState to update our non-existent appearance.
//     if (!mounted) return;

//     setState(() {});
//   }

//   Widget fillCards() {
//     List<Widget> widgets = _simCard
//         .map((SimCard sim) => Text(
//             'Sim Card Number: (${sim.countryPhonePrefix}) - ${sim.number}\nCarrier Name: ${sim.carrierName}\nCountry Iso: ${sim.countryIso}\nDisplay Name: ${sim.displayName}\nSim Slot Index: ${sim.slotIndex}\n\n'))
//         .toList();
//     return Column(children: widgets);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Plugin example app'),
//         ),
//         body: Center(
//           child: Column(
//             children: <Widget>[
//               Text('Running on: $_mobileNumber\n'),
//               fillCards()
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }