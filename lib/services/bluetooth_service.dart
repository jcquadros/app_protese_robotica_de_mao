import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

/// Uma classe de serviço para gerir toda a lógica de comunicação Bluetooth.
class AppBluetoothService extends ChangeNotifier {
  final Guid _serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Guid _characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  BluetoothDevice? _selectedDevice;

  final BehaviorSubject<BluetoothAdapterState> _adapterStateController = BehaviorSubject<BluetoothAdapterState>.seeded(BluetoothAdapterState.unknown);
  Stream<BluetoothAdapterState> get adapterState => _adapterStateController.stream;
  BluetoothAdapterState get currentAdapterState => _adapterStateController.value;

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  AppBluetoothService() {
    _initializeBluetoothMonitoring();
  }

  Future<void> _initializeBluetoothMonitoring() async {
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      _adapterStateController.add(BluetoothAdapterState.unavailable);
      return;
    }

    _adapterStateSubscription = FlutterBluePlus.adapterState.listen(
            (BluetoothAdapterState state) {
          print("Adapter State Changed: $state");
          _adapterStateController.add(state);

          if (state == BluetoothAdapterState.off) {
            // Optional: Stop scan, disconnect, clear device list if Bluetooth turns off
            stopScan();
          } else if (state == BluetoothAdapterState.on) {
            // Optional: You might want to trigger an automatic scan or other actions
            // when Bluetooth is turned back on.
          }
        },
        onError: (dynamic error) {
          print("Error listening to adapter state: $error");
          _adapterStateController.add(BluetoothAdapterState.unknown); // Or handle error appropriately
        }
    );
  }

  /// Inicia o escaneamento por dispositivos BLE.
  void startScan() async {
    await _requestPermissions();

    await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 15)
    );
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _selectedDevice = device;
      print("Connected to device: ${device.platformName}");
    } catch (e) {
      print("Error connecting: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
    _adapterStateSubscription?.cancel();
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
