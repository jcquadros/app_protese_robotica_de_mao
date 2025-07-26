import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Uma classe de serviço para gerir toda a lógica de comunicação Bluetooth.
class AppBluetoothService {
  final Guid _serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Guid _characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  BluetoothDevice? _selectedDevice;

  AppBluetoothService() {
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        FlutterBluePlus.onScanResults.listen((results) {
          if (results.isNotEmpty) {
            var result = results.first;
            var device = result.device;
            _selectedDevice = device;
            device.connectionState.listen((
                BluetoothConnectionState state) async {
              if (state == BluetoothConnectionState.disconnected) {
                print(
                    "${device.disconnectReason?.code} ${device.disconnectReason
                        ?.description}");
              }
            });

            _connectToDevice(device);
          }
        },
          onError: (e) => print(e),
        );
      } else {
        print("Bluetooth adapter is not on");
      }
    });
    _startScan();
  }

  /// Inicia o escaneamento por dispositivos BLE.
  void _startScan() async {
    await _requestPermissions();

    await FlutterBluePlus.startScan(
        withServices: [_serviceUuid],
        timeout: Duration(seconds: 15)
    );
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      print("Connected to device: ${device.platformName}");
    } catch (e) {
      print("Error connecting: $e");
    }
  }

  void dispose() {
    // Para a busca ao sair da tela para economizar recursos e bateria.
    FlutterBluePlus.stopScan();
    _selectedDevice?.disconnect();
  }

  void sendMessage(List<int> bytes) async {
    // Discover services
    List<BluetoothService> services = await _selectedDevice
        ?.discoverServices() ?? [];
    for (var service in services) {
      if (service.uuid == _serviceUuid) {
        print("Found service: ${service.uuid}");

        // Look for characteristic
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == _characteristicUuid) {
            print("Found characteristic, writing...");
            await characteristic.write(bytes, withoutResponse: false);
          }
        }
      }
    }
  }
}
