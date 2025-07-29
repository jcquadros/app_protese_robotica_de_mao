import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:mao_robotica_app/screens/bluetooth_not_enabled_screen.dart';
import 'package:mao_robotica_app/screens/location_not_enabled_screen.dart';
import 'package:mao_robotica_app/screens/main_screen.dart';
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  // Variáveis para controlar o estado da tela e a versão do Android
  bool? _isOldAndroid; // Será true para Android < 12
  Object? _currentScreen; // Guarda qual tela está visível

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateAppState();
    }
  }

  Future<void> _initialize() async {
    // Verifica a versão do Android apenas uma vez
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    setState(() {
      _isOldAndroid = androidInfo.version.sdkInt < 31; // Android 12 é SDK 31
    });

    final bluetoothService = Provider.of<AppBluetoothService>(context, listen: false);
    // // Initial check (important for when app starts with Bluetooth off)
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _handleAdapterStateChange(bluetoothService.currentAdapterState);
    // });
    _adapterStateSubscription = bluetoothService.adapterState.listen((_) => _updateAppState());
    
    // Faz a primeira verificação do estado
    _updateAppState();
  }

  Future<void> _updateAppState() async {
    if (!mounted) return;

    final bluetoothState = await FlutterBluePlus.adapterState.first;

    // Prioridade 1: Bluetooth desligado
    if (bluetoothState != BluetoothAdapterState.on) {
      if (_currentScreen != BluetoothNotEnabledScreen) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BluetoothNotEnabledScreen()),
          (route) => false,
        );
        setState(() { _currentScreen = BluetoothNotEnabledScreen; });
      }
      return;
    }

    // Prioridade 2: Localização desligada (APENAS em Androids antigos)
    if (_isOldAndroid == true) {
      final locationStatus = await Permission.location.serviceStatus;
      if (locationStatus.isDisabled) {
        if (_currentScreen != LocationNotEnabledScreen) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LocationNotEnabledScreen()),
            (route) => false,
          );
          setState(() { _currentScreen = LocationNotEnabledScreen; });
        }
        return;
      }
    }

    // Se tudo estiver OK, vai para a tela principal
    if (_currentScreen != MainScreen) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainScreen(
          bluetoothService: Provider.of<AppBluetoothService>(context, listen: false),
        )),
        (route) => false,
      );
      setState(() { _currentScreen = MainScreen; });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adapterStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Controle Mão Robótica',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyan, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}