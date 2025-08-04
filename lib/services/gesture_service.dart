import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mao_robotica_app/models/gesture.dart';
import 'package:mao_robotica_app/models/hand_command.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/predefined_gestures.dart';

class GestureService extends ChangeNotifier {
  static const _gesturesKey = 'custom_gestures';
  final Uuid _uuid = Uuid();

  List<Gesture> _gestures = [...predefinedGestures];

  List<Gesture> get gestures => _gestures;

  // Carrega os gestos salvos do disco.
  Future<void> loadGestures() async {
    final prefs = await SharedPreferences.getInstance();
    final gesturesString = prefs.getString(_gesturesKey);
    if (gesturesString != null) {
      final List<dynamic> gesturesJson = jsonDecode(gesturesString);
      _gestures = gesturesJson.map((json) => Gesture.fromJson(json)).toList();
      notifyListeners();
    }
  }

  // Adiciona um novo gesto e o salva no disco.
  Future<void> addGesture(String name, HandCommand command, Uint8List imageBytes) async {
    // Salva a imagem no diretório de documentos do app
    final directory = await getApplicationDocumentsDirectory();
    final imageId = _uuid.v4();
    final imagePath = '${directory.path}/$imageId.png';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(imageBytes);
    
    // Cria o novo gesto
    final newGesture = Gesture(
      id: imageId,
      name: name,
      isPredefined: false,
      imagePath: imagePath,
      command: command,
    );
    
    _gestures.add(newGesture);
    await _saveGestures();
    notifyListeners();
  }

  // Método para apagar um gesto.
  Future<void> deleteGesture(String gestureId) async {
    final gestureToRemove = _gestures.firstWhere((g) => g.id == gestureId);

    if (gestureToRemove.isPredefined) {
      return;
    }

    try {
      final imageFile = File(gestureToRemove.imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      print("Erro ao apagar o arquivo de imagem: $e");
    }
    _gestures.removeWhere((g) => g.id == gestureId);
    await _saveGestures();
    notifyListeners();
  }

  // Salva a lista atual de gestos no SharedPreferences.
  Future<void> _saveGestures() async {
    final prefs = await SharedPreferences.getInstance();
    final gesturesJson = _gestures.map((g) => g.toJson()).toList();
    await prefs.setString(_gesturesKey, jsonEncode(gesturesJson));
  }
}