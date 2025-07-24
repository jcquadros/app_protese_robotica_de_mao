import 'dart:io'; // Importado para verificar a plataforma (Android/iOS)
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mao_robotica_app/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/bluetooth_service.dart';
import 'dart:async';

/// Tela para escanear e conectar a dispositivos Bluetooth.
class BluetoothConnectionScreen extends StatefulWidget {
  final AppBluetoothService service;
  const BluetoothConnectionScreen({super.key, required this.service});

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  final Guid serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Guid characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  late BluetoothDevice selectedDevice;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        FlutterBluePlus.onScanResults.listen((results) {
          if (results.isNotEmpty) {
            var result = results.first;
            var device = result.device;
            selectedDevice = device;
            device.connectionState.listen((BluetoothConnectionState state) async {
              if (state == BluetoothConnectionState.disconnected) {
                // 1. typically, start a periodic timer that tries to
                //    reconnect, or just call connect() again right now
                // 2. you must always re-discover services after disconnection!
                print("${device.disconnectReason?.code} ${device.disconnectReason?.description}");
              }
            });

            connectToDevice(device);
          }
        },
          onError: (e) => print(e),
        );
      } else {
        // show an error to the user, etc
      }
    });
  }

  Future<void> test() async {
    await FlutterBluePlus.startScan(
        withServices: [serviceUuid],
        timeout: Duration(seconds:15)
    );
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      print("Connected to device: ${device.name}");
      sendMessage();
    } catch (e) {
      print("Error connecting: $e");
    }
  }

  @override
  void dispose() {
    // Para a busca ao sair da tela para economizar recursos e bateria.
    widget.service.stopScan();
    super.dispose();
  }

  void sendMessage() async {
    // Discover services
    List<BluetoothService> services = await selectedDevice.discoverServices();
    for (var service in services) {
      if (service.uuid == serviceUuid) {
        print("Found service: ${service.uuid}");

        // Look for characteristic
        for (var characteristic in service.characteristics) {

          var message = "Hello World!";
          if (characteristic.uuid == characteristicUuid) {
            print("Found characteristic, writing...");

            // Convert string to bytes and write
            List<int> bytes = message.codeUnits; // UTF-8 by default
            await characteristic.write(bytes, withoutResponse: false);

            print("Message written: $message");
          }
        }
      }
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Bluetooth Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: test,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => sendMessage(),
          )
        ],
      ),
      body: null
    );
  }
}