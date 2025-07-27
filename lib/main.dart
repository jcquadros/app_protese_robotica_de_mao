import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:mao_robotica_app/screens/bluetooth_not_enabled_screen.dart';
import 'package:mao_robotica_app/screens/main_screen.dart';
import 'models/hand_command.dart';
import 'services/bluetooth_service.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppBluetoothService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  bool _isBluetoothOffPageVisible = true;

  @override
  void initState() {
    super.initState();
    final bluetoothService = Provider.of<AppBluetoothService>(
        context, listen: false);

    // Initial check (important for when app starts with Bluetooth off)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAdapterStateChange(bluetoothService.currentAdapterState);
    });

    _adapterStateSubscription = bluetoothService.adapterState.listen(_handleAdapterStateChange);
  }

  void _handleAdapterStateChange(BluetoothAdapterState state) {
    if (mounted) {
      if (state == BluetoothAdapterState.on) {
        if (_isBluetoothOffPageVisible) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) =>
                MainScreen(
                    bluetoothService: Provider.of<AppBluetoothService>(context, listen: false),)
                ),
                (route) => false,
          );
          setState(() {
            _isBluetoothOffPageVisible = false;
          });
        }
      }
      else {
        if (!_isBluetoothOffPageVisible) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (_) => const BluetoothNotEnabledScreen()),
                (route) => false,
          );
          setState(() {
            _isBluetoothOffPageVisible = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    super.dispose();
  }

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
      home: Consumer<AppBluetoothService>(
        builder: (context, bluetoothService, child) {
          final initialState = bluetoothService.currentAdapterState;

          if (initialState == BluetoothAdapterState.on) {
            _isBluetoothOffPageVisible = false;
            return MainScreen(bluetoothService: bluetoothService);
          }

          return const BluetoothNotEnabledScreen();
        },
      ),
    );
  }
}