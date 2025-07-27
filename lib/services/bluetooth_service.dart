import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

/// Uma classe de serviço para gerir toda a lógica de comunicação Bluetooth.
class AppBluetoothService extends ChangeNotifier {
  final Guid _serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Guid _characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  BluetoothDevice? _connectedDevice;

  final BehaviorSubject<BluetoothAdapterState> _adapterStateController = BehaviorSubject<BluetoothAdapterState>.seeded(BluetoothAdapterState.unknown);
  Stream<BluetoothAdapterState> get adapterState => _adapterStateController.stream;
  BluetoothAdapterState get currentAdapterState => _adapterStateController.value;

  final BehaviorSubject<BluetoothConnectionState> _connectionStateController = BehaviorSubject<BluetoothConnectionState>.seeded(BluetoothConnectionState.disconnected);
  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;
  BluetoothConnectionState get currentConnectionState => _connectionStateController.value;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

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
      // Cancel any previous connection
      await disconnectFromDevice();

      // Listen to the device's connection state stream
      _connectionStateSubscription = device.connectionState.listen((BluetoothConnectionState state) {
        _connectionStateController.add(state);

        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null; // And this
          // ...
        }});

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      print("Connected to device: ${device.platformName}");
    } catch (e) {
      print("Error connecting: $e");
    }
  }

  Future<void> disconnectFromDevice({bool clearUserRequest = true}) async {
    if (_connectedDevice == null) {
      print("No device is currently connected to disconnect from.");
      if (_connectionStateController.value != BluetoothConnectionState.disconnected) {
        // Ensure state consistency if called erroneously
        _connectionStateController.add(BluetoothConnectionState.disconnected);
      }
      return;
    }

    final deviceToDisconnect = _connectedDevice!; // Capture for logging after potential nullification
    print("Disconnecting from ${deviceToDisconnect.platformName} (${deviceToDisconnect.remoteId})...");

    try {
      await deviceToDisconnect.disconnect();
      // The device.connectionState listener (if still active) should update the
      // _connectionStateController to BluetoothConnectionState.disconnected.
      // If the disconnect call completes, it's a strong indication of success.
      print("${deviceToDisconnect.platformName} disconnect call initiated successfully.");
      // We don't nullify _connectedDevice here directly; let the stream listener handle it
      // to maintain a single source of truth for that state change.
    } catch (e) {
      print("Error during disconnect call for ${deviceToDisconnect.platformName}: $e");
      // If the disconnect call itself fails, it's possible the device is still connected
      // or the connection state is indeterminate from this call alone.
      // Rely on the connectionState stream or assume disconnected if it's a critical error.
      // For robustness, if an error occurs here, we might force the state.
      if (_connectionStateController.value != BluetoothConnectionState.disconnected) {
        _connectionStateController.add(BluetoothConnectionState.disconnected);
      }
      if (_connectedDevice?.remoteId == deviceToDisconnect.remoteId) {
        _connectedDevice = null; // Clear if it's still this device
      }
    } finally {
      // It's crucial to cancel the subscription to the device's connection state
      // once we intend to disconnect, to prevent old listeners from interfering
      // or trying to manage a device we no longer care about.
      if (_connectedDevice?.remoteId == deviceToDisconnect.remoteId || clearUserRequest) {
        // Only cancel if it's still the same device, or if it's a user-initiated disconnect.
        await _connectionStateSubscription?.cancel();
        _connectionStateSubscription = null;
        if (clearUserRequest) {
          // If it's a user request, we definitely clear the connected device reference
          // as the intention is to be fully disconnected.
          _connectedDevice = null;
          // Ensure the state reflects disconnected if it hasn't already by the stream
          if(_connectionStateController.value != BluetoothConnectionState.disconnected) {
            _connectionStateController.add(BluetoothConnectionState.disconnected);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    _adapterStateSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  void sendMessage(List<int> bytes) async {
    // Discover services
    List<BluetoothService> services = await _connectedDevice
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
