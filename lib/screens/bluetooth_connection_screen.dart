import 'dart:async'; // For StreamSubscription

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // For BluetoothDevice type
import '../services/bluetooth_service.dart';

/// Tela para escanear e conectar a dispositivos Bluetooth.
class BluetoothConnectionScreen extends StatefulWidget {
  final AppBluetoothService bluetoothService;

  const BluetoothConnectionScreen({Key? key, required this.bluetoothService})
      : super(key: key);

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  List<BluetoothDevice> _availableDevices = [];
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription =
        FlutterBluePlus.onScanResults.listen((results) {
          // Filter out devices without a name to keep the list cleaner
          // And update the list of available devices
          setState(() {
            _availableDevices = results
                .where((result) =>
            result.device.platformName.isNotEmpty ||
                result.advertisementData.advName.isNotEmpty)
                .map((result) => result.device)
                .toList();
            // Simple de-duplication based on remoteId
            _availableDevices = _availableDevices.toSet().toList();
          });
        });

    // Listen to scanning state
    _isScanningSubscription =
        FlutterBluePlus.isScanning.listen((isScanning) {
          setState(() {
            _isScanning = isScanning;
          });
        });

    // Start scanning when the screen is initialized
    _startScan();
  }

  @override
  void dispose() {
    _stopScan(); // Stop scanning when the screen is disposed
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    super.dispose();
  }

  void _startScan() {
    widget.bluetoothService.startScan();
  }

  void _stopScan() {
    widget.bluetoothService.stopScan();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _stopScan(); // Stop scanning before attempting to connect
    // Show a loading indicator or feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Conectando a ${device.platformName}...')),
    );
    try {
      await widget.bluetoothService.connectToDevice(device);
      // Listen to connection state changes specifically for the connection attempt
      // You might already have a global listener in your service, adapt as needed
      var sub = device.connectionState.listen((state) {
        if (mounted) { // Check if the widget is still in the tree
          if (state == BluetoothConnectionState.connected) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Conectado a ${device.platformName}!')),
            );
            Navigator.pop(
                context); // Go back to the previous screen on successful connection
          } else if (state == BluetoothConnectionState.disconnected) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Falha ao conectar a ${device.platformName}.')),
            );
          }
        }
      });
      // Consider a timeout for the subscription or a more robust way to handle this
      // For example, if connectToDevice itself updates a stream that indicates success/failure.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao conectar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos Bluetooth'),
        actions: [
          _isScanning
              ? IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: 'Parar Busca',
            onPressed: _stopScan,
          )
              : IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Buscar Novamente',
            onPressed: _startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Buscando dispositivos...'),
                ],
              ),
            ),
          Expanded(
            child: _availableDevices.isEmpty && !_isScanning
                ? const Center(
              child: Text(
                  'Nenhum dispositivo encontrado. Toque em buscar para tentar novamente.'),
            )
                : ListView.builder(
              itemCount: _availableDevices.length,
              itemBuilder: (context, index) {
                final device = _availableDevices[index];
                final deviceName = device.platformName.isNotEmpty
                    ? device.platformName
                    : 'Dispositivo Desconhecido';
                return ListTile(
                  leading: const Icon(Icons.bluetooth_drive),
                  // Or other relevant icon
                  title: Text(deviceName),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _connectToDevice(device);
                    },
                    child: const Text('Conectar'),
                  ),
                  // You could add an onTap to show more details or RSSI
                  // onTap: () => print('Tapped on ${device.platformName}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
