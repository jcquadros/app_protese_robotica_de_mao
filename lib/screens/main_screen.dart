import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mao_robotica_app/screens/voice_control_screen.dart';
import 'package:provider/provider.dart';

import '../models/hand_command.dart';
import '../services/bluetooth_service.dart';
import 'bluetooth_connection_screen.dart';
import 'finger_control_screen.dart';
import 'gestures_screen.dart';

/// A tela principal que contém a navegação por abas.
class MainScreen extends StatefulWidget {
  final AppBluetoothService bluetoothService;

  const MainScreen({super.key, required this.bluetoothService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void _sendCommand(HandCommand command) {
    final bluetoothService = Provider.of<AppBluetoothService>(
        context, listen: false);

    if (bluetoothService.currentConnectionState != BluetoothConnectionState.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhum dispositivo conectado'), duration: const Duration(seconds: 1)),
      );
      return;
    }

    var serializedCommand = json.encode(command.toJson()).codeUnits;
    bluetoothService.sendMessage(serializedCommand);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enviando comando'), duration: const Duration(seconds: 1)),
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
              stream: widget.bluetoothService.connectionState,
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
                        builder: (context) => BluetoothConnectionScreen(bluetoothService: widget.bluetoothService)));
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