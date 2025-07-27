import 'package:flutter/material.dart';

class BluetoothNotEnabledScreen extends StatelessWidget {
  const BluetoothNotEnabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope( // Prevents user from easily swiping back if modal
      canPop: false, // User must enable Bluetooth to proceed
      child: Scaffold(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.bluetooth_disabled,
                  size: 100,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Bluetooth Desativado',
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Para utilizar as funcionalidades de controle da mão robótica, por favor, ative o Bluetooth do seu dispositivo.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  "O aplicativo continuará assim que o Bluetooth for ativado.",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
