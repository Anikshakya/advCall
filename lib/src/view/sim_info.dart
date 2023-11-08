import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sim_data/sim_data.dart';
import 'package:sim_data/sim_model.dart' as sim;
import 'package:simnumber/siminfo.dart';
import 'package:simnumber/sim_number.dart';

class SimInfoScreen extends StatefulWidget {
  const SimInfoScreen({Key? key}) : super(key: key);

  @override
  State<SimInfoScreen> createState() => _SimInfoScreenState();
}

class _SimInfoScreenState extends State<SimInfoScreen> {
  SimInfo simInfo = SimInfo([]);
  bool _isLoading = true;
  SimData? _simData;
  @override
  void initState() {
    super.initState();
    SimNumber.listenPhonePermission((isPermissionGranted) {
      print("isPermissionGranted : $isPermissionGranted");
      if (isPermissionGranted) {
        initPlatformState();
      } else {}
    });
    initPlatformState();
    init();
  }

  Future<void> init() async {
    SimData simData;
    try {
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        bool isGranted = await Permission.phone.request().isGranted;
        if (!isGranted) return;
      }
      simData = await SimDataPlugin.getSimData();
      setState(() {
        _isLoading = false;
        _simData = simData;
      });
      void printSimCardsData() async {
        try {
          SimData simData = await SimDataPlugin.getSimData();
          for (var s in simData.cards) {
            // ignore: avoid_print
            print('Serial number: ${s.serialNumber}');
          }
        } on PlatformException catch (e) {
          debugPrint("error! code: ${e.code} - message: ${e.message}");
        }
      }

      printSimCardsData();
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _isLoading = false;
        _simData = null;
      });
    }
  }
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    try {
      simInfo = await SimNumber.getSimData();
      setState(() {});
    } on PlatformException {
      print("simInfo  : " "2");
    }
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: () {
            Get.back();
          }, icon: const Icon(Icons.arrow_back_ios_rounded) ),
          title: const Text('Plugin example app'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            setState(() {
              
            });
          },
          child: const Icon(Icons.refresh)
        ),
        body: Column(
          children: [
            simInfo.cards.isEmpty
                ? const Text("No SIM Card Found")
                : Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: simInfo.cards
                          .map((e) => Row(
                            children: [
                              const Column(
                                children: [
                                  Text("Slot"),
                                  Text("Phone Number"),
                                  Text("Carrier"),
                                  Text("Name"),
                                  Text("Country ISo"),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(e.slotIndex.toString()),
                                  Text(e.phoneNumber.toString()),
                                  Text(e.carrierName.toString()),
                                  Text(e.displayName.toString()),
                                  Text(e.countryIso.toString()),
                                ],
                              ),
                            ],
                          ) )
                          .toList(),
                    ),
                  ),
           Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: _simData?.cards != null
                    ? _simData!.cards.isEmpty
                        ? [const Text('No sim card present')]
                        : _simData!.cards
                            .map(
                              (sim.SimCard card) => ListTile(
                                leading: const Icon(Icons.sim_card),
                                title: Text('Card ${card.slotIndex}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text('carrierName: ${card.carrierName}'),
                                    Text('countryCode: ${card.countryCode}'),
                                    Text('displayName: ${card.displayName}'),
                                    Text(
                                        'isDataRoaming: ${card.isDataRoaming}'),
                                    Text(
                                        'isNetworkRoaming: ${card.isNetworkRoaming}'),
                                    Text('mcc: ${card.mcc}'),
                                    Text('mnc: ${card.mnc}'),
                                    Text('slotIndex: ${card.slotIndex}'),
                                    Text('serialNumber: ${card.serialNumber}'),
                                    Text(
                                        'subscriptionId: ${card.subscriptionId}'),
                                  ],
                                ),
                              ),
                            )
                            .toList()
                    : [
                        Center(
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Failed to load data'),
                        )
                      ],
              ),
            )
          ],
        ),
      ),
    );
  }
}