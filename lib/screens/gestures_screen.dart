import 'package:flutter/material.dart';
import 'package:mao_robotica_app/models/hand_command.dart';
import '../constants/predefined_commands.dart';
import '../widgets/gesture_card.dart';

/// Uma tela que exibe uma grade de gestos pré-definidos que podem ser enviados.
class GesturesScreen extends StatelessWidget {
  /// Callback para enviar o comando de um gesto específico quando um cartão é tocado.
  final Function(HandCommand) onSendCommand;
  
  GesturesScreen({super.key, required this.onSendCommand});

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
      itemCount: predefinedGestures.length,
      itemBuilder: (context, index) {
        final gesture = predefinedGestures[index];
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