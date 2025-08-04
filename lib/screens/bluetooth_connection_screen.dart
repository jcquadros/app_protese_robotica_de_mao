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
  List<BluetoothDevice> _scannedDevices = [];
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  bool _isScanning = false;
  BluetoothDevice? _currentlyConnectedDevice;

  @override
  void initState() {
    super.initState();

    _currentlyConnectedDevice = widget.bluetoothService.connectedDevice;

    _scanResultsSubscription =
        FlutterBluePlus.scanResults.listen((results) {
          if (mounted) {
            setState(() {
              _scannedDevices = results
                  .where((result) =>
              result.device.platformName.isNotEmpty ||
                  result.advertisementData.advName.isNotEmpty)
                  .map((result) => result.device)
                  .toList();
            });
          }
        });

    // Listen to connection state changes to update the _currentlyConnectedDevice
    _connectionStateSubscription = widget.bluetoothService.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          if (state == BluetoothConnectionState.connected) {
            _currentlyConnectedDevice = widget.bluetoothService.connectedDevice;
          } else if (state == BluetoothConnectionState.disconnected) {
            _currentlyConnectedDevice = null;
          }
        });
      }
    });

    _scanResultsSubscription =
        FlutterBluePlus.onScanResults.listen((results) {
          // Filter out devices without a name to keep the list cleaner
          // And update the list of available devices
          setState(() {
            _scannedDevices = results
                .where((result) =>
            result.device.platformName.isNotEmpty ||
                result.advertisementData.advName.isNotEmpty)
                .map((result) => result.device)
                .toList();
            // Simple de-duplication based on remoteId
            _scannedDevices = _scannedDevices.toSet().toList();
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

  Future<void> _disconnectFromDevice() async {
    _stopScan(); // Stop scanning before attempting to disconnect
    // Show a loading indicator or feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Desconectando de ${widget.bluetoothService.connectedDevice?.platformName}...')),
    );
    try {
      await widget.bluetoothService.disconnectFromDevice();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao desconectar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine connected device with scanned devices, ensuring no duplicates
    // and potentially prioritizing the connected device.
    List<BluetoothDevice> displayDevices = [];
    Set<String> displayedIds = {}; // To handle de-duplication

    // Add connected device first if it exists
    if (_currentlyConnectedDevice != null) {
      displayDevices.add(_currentlyConnectedDevice!);
      displayedIds.add(_currentlyConnectedDevice!.remoteId.toString());
    }

    // Add scanned devices, avoiding duplicates
    for (var device in _scannedDevices) {
      if (!displayedIds.contains(device.remoteId.toString())) {
        displayDevices.add(device);
        displayedIds.add(device.remoteId.toString());
      }
    }

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
              padding: EdgeInsets.only(top: 10.0, right: 8.0, left: 8.0, bottom: 25.0),
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
            child: displayDevices.isEmpty && !_isScanning
                ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0), // Adjust value as needed
                child: Text(
                  'Nenhum dispositivo encontrado. Toque no ícone de atualizar para buscar novamente.', // Updated text slightly
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                ),
              ),
            )
                : ListView.builder(
              itemCount: displayDevices.length,
              itemBuilder: (context, index) {
                final device = displayDevices[index];
                final deviceName = device.platformName.isNotEmpty
                    ? device.platformName
                    : 'Dispositivo Desconhecido';
                final bool isConnected = _currentlyConnectedDevice?.remoteId ==
                    device.remoteId;
                return ListTile(
                  leading: Icon(
                    isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                    color: isConnected ? Colors.lightBlue : null,
                  ),
                  title: Text(deviceName),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: isConnected
                      ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
                    onPressed: () {
                      _disconnectFromDevice();
                    },
                    child: const Text('Desconectar', style: TextStyle(color: Colors.white)),
                  )
                      : ElevatedButton(
                    onPressed: () {
                      _connectToDevice(device);
                    },
                    child: const Text('Conectar'),
                  ),
                  tileColor: isConnected ? Colors.lightBlueAccent.withValues(alpha: 0.07) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
