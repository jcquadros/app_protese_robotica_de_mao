import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// --- Blueprint da Comunicação ---
/// UUID do serviço Bluetooth principal da mão robótica.
const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
/// UUID da característica usada para enviar comandos.
const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

// --- Configuração da API do Gemini ---
/// Chave de API para o serviço do Google Gemini.
const String GEMINI_API_KEY = "AIzaSyCLzrm9W6PJFMbrgYeG4OSD4Uj1heF_ZaM";
/// URL do endpoint da API do Gemini.
const String GEMINI_API_URL =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$GEMINI_API_KEY";

// --- Variáveis Globais de Estado do Bluetooth ---
/// A característica BLE para a qual os comandos serão escritos.
BluetoothCharacteristic? targetCharacteristic;
/// O dispositivo BLE atualmente conectado.
BluetoothDevice? connectedDevice;
/// Stream que emite o estado atual da conexão para a UI.
Stream<BluetoothConnectionState> connectionStateStream = Stream.empty(); 