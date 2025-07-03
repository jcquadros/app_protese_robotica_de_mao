import 'dart:io'; // Importado para verificar a plataforma (Android/iOS)
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/bluetooth_service.dart';

/// Tela para escanear e conectar a dispositivos Bluetooth.
class BluetoothConnectionScreen extends StatefulWidget {
  final AppBluetoothService service;
  const BluetoothConnectionScreen({super.key, required this.service});

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  
  @override
  void initState() {
    super.initState();
    // Inicia a busca por dispositivos assim que a tela é construída.
    _checkPermissionsAndScan();
  }

  @override
  void dispose() {
    // Para a busca ao sair da tela para economizar recursos e bateria.
    widget.service.stopScan();
    super.dispose();
  }

  /// Verifica todas as condições necessárias (Bluetooth, Permissões, Localização) antes de escanear.
  Future<void> _checkPermissionsAndScan() async {
    print("[LOG] Verificando permissões e status...");
    // 1. Verifica primeiro se o Bluetooth do celular está ligado.
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      print("[LOG] ERRO: Bluetooth está desligado.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bluetooth está desligado. Por favor, ative-o.'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    // 2. Pede todas as permissões necessárias de uma vez.
    if (Platform.isAndroid) {
      var permissions = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      if (permissions[Permission.location]!.isDenied ||
          permissions[Permission.bluetoothScan]!.isDenied ||
          permissions[Permission.bluetoothConnect]!.isDenied) {
        print("[LOG] ERRO: Uma ou mais permissões foram negadas.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Permissões de Localização e Bluetooth são necessárias para continuar.'),
          ));
        }
        return;
      }
    }
    
    // 3. Verifica se o serviço de localização (GPS) está ligado.
    var isLocationServiceEnabled = await Permission.location.serviceStatus.isEnabled;
    if (!isLocationServiceEnabled) {
      print("[LOG] ERRO: Serviços de Localização (GPS) estão desligados.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Por favor, ative os Serviços de Localização (GPS).')));
      }
      return;
    }

    // 4. Se tudo estiver OK, inicia o scan.
    print("[LOG] Todas as verificações passaram. Iniciando o scan...");
    widget.service.startScan();
  }

  /// Tenta se conectar a um dispositivo e atualiza a UI de acordo com o resultado.
  Future<void> _connectToDevice(BluetoothDevice device) async {
    bool success = await widget.service.connectToDevice(device);

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao conectar ao dispositivo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar Dispositivo'),
        actions: [
          StreamBuilder<bool>(
            stream: FlutterBluePlus.isScanning,
            initialData: false,
            builder: (c, snapshot) {
              final isScanning = snapshot.data ?? false;
              return IconButton(
                icon: isScanning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.search),
                onPressed: _checkPermissionsAndScan,
              );
            },
          ),
        ],
      ),
      // ATUALIZAÇÃO: Adicionado RefreshIndicator para permitir "puxar para atualizar".
      body: RefreshIndicator(
        onRefresh: _checkPermissionsAndScan,
        child: StreamBuilder<List<ScanResult>>(
          stream: widget.service.scanResults,
          initialData: const [],
          builder: (c, snapshot) {
            // ATUALIZAÇÃO: Adicionado log para cada vez que o stream atualiza.
            print("[LOG] Stream de resultados atualizado. Encontrados: ${snapshot.data?.length ?? 0} dispositivos.");

            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text("Nenhum dispositivo encontrado.\nVerifique se o dispositivo está ligado e anunciando.\nPuxe para baixo para escanear novamente.", textAlign: TextAlign.center),
              );
            }
            return ListView(
              // ATUALIZAÇÃO: Removido o filtro `.where()` para mostrar TODOS os dispositivos.
              children: (snapshot.data ?? [])
                  .map(
                    (r) {
                      // ATUALIZAÇÃO: Adicionado log para cada dispositivo na lista.
                      print("[LOG] Dispositivo encontrado: Nome: '${r.device.platformName}', ID: ${r.device.remoteId}");
                      return ListTile(
                        title: Text(r.device.platformName.isNotEmpty ? r.device.platformName : "Dispositivo Desconhecido"),
                        subtitle: Text(r.device.remoteId.toString()),
                        trailing: ElevatedButton(
                          child: const Text('Conectar'),
                          onPressed: () => _connectToDevice(r.device),
                        ),
                      );
                    }
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
