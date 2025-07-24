import 'dart:io'; // Importado para verificar a plataforma (Android/iOS)
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/bluetooth_service.dart';
import 'dart:async';

/// Tela para escanear e conectar a dispositivos Bluetooth.
class BluetoothConnectionScreen extends StatefulWidget {
  final AppBluetoothService service;
  const BluetoothConnectionScreen({super.key, required this.service});

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();

    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      FlutterBluePlus.scanResults.listen((results){
        print(results);
      });
    });
  }

  @override
  void dispose() {
    // Para a busca ao sair da tela para economizar recursos e bateria.
    widget.service.stopScan();
    _adapterStateStateSubscription.cancel();
    super.dispose();
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
            onPressed: () => {},
          )
        ],
      ),
      body: null
    );
  }
}
