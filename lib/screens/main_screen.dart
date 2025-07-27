import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mao_robotica_app/screens/voice_control_screen.dart';

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
    var serializedCommand = json.encode(command.toJson()).codeUnits;
    widget.bluetoothService.sendMessage(serializedCommand);

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
            IconButton(
              icon: Icon(Icons.bluetooth_connected, color: Colors.grey),
              onPressed: () {
                // Navega para a tela de conexão
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BluetoothConnectionScreen(bluetoothService: widget.bluetoothService),
                  ),
                );
              },
            )
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