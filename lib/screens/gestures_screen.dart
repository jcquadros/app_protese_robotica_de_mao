import 'package:flutter/material.dart';
import 'package:mao_robotica_app/models/hand_command.dart';
import '../widgets/gesture_card.dart'; // Importa o widget de cartão reutilizável.

/// Uma tela que exibe uma grade de gestos pré-definidos que podem ser enviados.
class GesturesScreen extends StatelessWidget {
  /// Callback para enviar o comando de um gesto específico quando um cartão é tocado.
  final Function(HandCommand) onSendCommand;
  
  GesturesScreen({super.key, required this.onSendCommand});

  /// Lista de dados que define cada gesto, incluindo nome, imagem e o comando a ser enviado.
  final List<Map<String, dynamic>> gestures = [
    {
      'name': 'Faz o L',
      'image': 'assets/images/fazoele.png',
      'command': HandCommand(
        thumb: 0,   // polegar estendido
        index: 0,   // indicador estendido
        middle: 100,
        ring: 100,
        pinky: 100,
      ),
    },
    {
      'name': 'Joia',
      'image': 'assets/images/joia.png',
      'command': HandCommand(
        thumb: 0,   // polegar para cima
        index: 100,
        middle: 100,
        ring: 100,
        pinky: 100,
      ),
    },
    {
      'name': 'Paz',
      'image': 'assets/images/paz.png',
      'command': HandCommand(
        thumb: 100,
        index: 0,
        middle: 0,
        ring: 100,
        pinky: 100,
      ),
    },
    {
      'name': 'Rock',
      'image': 'assets/images/rock.png',
      'command': HandCommand(
        thumb: 100,
        index: 0,
        middle: 100,
        ring: 100,
        pinky: 0,
      ),
    },
    {
      'name': 'OK',
      'image': 'assets/images/ok.png',
      'command': HandCommand(
        thumb: 0,
        index: 0,
        middle: 100,
        ring: 100,
        pinky: 100,
      ),
    },
    {
      'name': 'Apontar',
      'image': 'assets/images/apontar.png',
      'command': HandCommand(
        thumb: 50,
        index: 0,
        middle: 100,
        ring: 100,
        pinky: 100,
      ),
    },
    {
      'name': 'Parar',
      'image': 'assets/images/parar.png',
      'command': HandCommand(
        thumb: 0,
        index: 0,
        middle: 0,
        ring: 0,
        pinky: 0,
      ),
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Usa GridView.builder para construir a grade de forma eficiente,
    // criando os itens conforme eles se tornam visíveis na tela.
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      // Define a estrutura da grade: 2 colunas, espaçamentos e proporção dos itens.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.85,
      ),
      itemCount: gestures.length,
      itemBuilder: (context, index) {
        final gesture = gestures[index];
        // Para cada item na lista de gestos, cria um GestureCard.
        return GestureCard(
          name: gesture['name']!,
          imagePath: gesture['image']!,
          // Ao tocar no cartão, o comando específico do gesto é enviado.
          onTap: () => onSendCommand(gesture['command']!),
        );
      },
    );
  }
}