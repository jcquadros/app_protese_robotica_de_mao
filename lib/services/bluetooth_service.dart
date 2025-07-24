import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mao_robotica_app/models/hand_command.dart';
import '../constants.dart';

/// Uma classe de serviço para gerir toda a lógica de comunicação Bluetooth.
class AppBluetoothService {
  /// Stream que emite os resultados do escaneamento de dispositivos.
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  
  // ATUALIZAÇÃO: Usamos nosso próprio controller para ter controle total do estado.
  final StreamController<BluetoothConnectionState> _connectionStateController =
      StreamController.broadcast();
  
  /// Stream que emite o estado da conexão do dispositivo atualmente conectado.
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;

  /// Inicia o escaneamento por dispositivos BLE por 5 segundos.
  void startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  /// Para o escaneamento por dispositivos BLE.
  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  /// Tenta conectar-se a um dispositivo e descobrir o serviço e a característica corretos.
  Future<bool> connectToDevice(BluetoothDevice device) async {
    stopScan();
    try {
      // Emitimos o estado 'conectando' para a UI.
      _connectionStateController.add(BluetoothConnectionState.connecting);
      await device.connect();
      _connectedDevice = device;
      
      // Descobre os serviços e, se for bem-sucedido, atualiza o estado.
      await _discoverServices();
      
      return _targetCharacteristic != null;
    } catch (e) {
      print("Erro ao conectar: $e");
      _connectionStateController.add(BluetoothConnectionState.disconnected);
      return false;
    }
  }

  /// Desconecta do dispositivo atual.
  void disconnect() {
    _connectedDevice?.disconnect();
    _connectedDevice = null;
    _targetCharacteristic = null;
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  /// Procura pelo serviço e característica específicos no dispositivo conectado.
  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
              _targetCharacteristic = characteristic;
              print("Característica encontrada!");
              
              // ATUALIZAÇÃO: SÓ AGORA nós emitimos o estado 'conectado'.
              _connectionStateController.add(BluetoothConnectionState.connected);
              return;
            }
          }
        }
      }
    } catch (e) {
      print("Erro ao descobrir serviços: $e");
      _connectionStateController.add(BluetoothConnectionState.disconnected);
    }
  }

  /// Envia um comando de texto para a mão robótica.
  void sendCommand(HandCommand command) {
    return;
    if (_targetCharacteristic != null) {
      List<int> bytes = utf8.encode(command.toString());
      _targetCharacteristic!.write(bytes);
      print("Comando enviado: $command");
    } else {
      print("Nenhuma característica alvo encontrada para enviar comando.");
    }
  }

  /// Limpa os recursos do controller ao final do ciclo de vida.
  void dispose() {
    _connectionStateController.close();
  }
}
