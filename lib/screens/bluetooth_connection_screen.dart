import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

/// Tela para escanear e conectar a dispositivos Bluetooth.
class BluetoothConnectionScreen extends StatefulWidget {
  final AppBluetoothService service;
  const BluetoothConnectionScreen({super.key, required this.service});

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Bluetooth Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: null
    );
  }
}