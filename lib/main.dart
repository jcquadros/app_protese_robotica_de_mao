import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mao_robotica_app/models/hand_command.dart';
import 'services/bluetooth_service.dart';
import 'screens/gestures_screen.dart';
import 'screens/finger_control_screen.dart';
import 'screens/voice_control_screen.dart';
import 'screens/bluetooth_connection_screen.dart';

/// Ponto de entrada principal da aplicação Flutter.
void main() {
  runApp(const MyApp());
}

/// O widget raiz da aplicação.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Mão Robótica',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyan, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: MainScreen(bluetoothService: AppBluetoothService()), // Usa a classe renomeada
    );
  }
}

/// A tela principal que contém a navegação por abas.
class MainScreen extends StatefulWidget {
  final AppBluetoothService bluetoothService; // Usa a classe renomeada
  const MainScreen({super.key, required this.bluetoothService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  
  /// Wrapper para a função de envio de comando do serviço.
  void _sendCommand(HandCommand command) {
    widget.bluetoothService.sendCommand(command);
    // O feedback visual pode ser adicionado aqui, se desejado.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulando envio: $command'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Controle Mão Robótica'),
          actions: [
            StreamBuilder<BluetoothConnectionState>(
              stream: widget.bluetoothService.connectionStateStream,
              initialData: BluetoothConnectionState.disconnected,
              builder: (c, snapshot) {
                IconData icon;
                Color color;
                if (snapshot.data == BluetoothConnectionState.connected) {
                  icon = Icons.bluetooth_connected;
                  color = Colors.lightBlueAccent;
                } else {
                  icon = Icons.bluetooth_disabled;
                  color = Colors.grey;
                }
                return IconButton(
                  icon: Icon(icon, color: color),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => BluetoothConnectionScreen(service: widget.bluetoothService)));
                  },
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sign_language), text: 'Gestos'),
              Tab(icon: Icon(Icons.fingerprint), text: 'Dedos'),
              Tab(icon: Icon(Icons.mic), text: 'Voz'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GesturesScreen(onSendCommand: _sendCommand),
            FingerControlScreen(onSendCommand: _sendCommand),
            VoiceControlScreen(onSendCommand: _sendCommand),
          ],
        ),
      ),
    );
  }
}