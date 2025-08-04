import 'package:flutter/material.dart';
import 'package:mao_robotica_app/models/gesture.dart';
import 'package:mao_robotica_app/services/gesture_service.dart';
import 'package:provider/provider.dart';

import '../models/hand_command.dart';
import '../widgets/gesture_card.dart';

class GesturesScreen extends StatelessWidget {
  final Function(HandCommand) onSendCommand;

  const GesturesScreen({super.key, required this.onSendCommand});

  void _showDeleteConfirmationDialog(BuildContext context, Gesture gesture) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Apagar Gesto'),
          content: Text('Você tem certeza que deseja apagar o gesto "${gesture.name}"? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Apagar'),
              onPressed: () {
                // Usa o Provider para acessar o serviço e apagar
                Provider.of<GestureService>(context, listen: false)
                    .deleteGesture(gesture.id);
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gesto "${gesture.name}" apagado.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // MODIFICADO: Usa um Consumer para ouvir as mudanças no GestureService
    return Consumer<GestureService>(
      builder: (context, gestureService, child) {
        if (gestureService.gestures.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum gesto salvo.\nVá para a aba "Dedos" para criar um!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.85,
          ),
          itemCount: gestureService.gestures.length,
          itemBuilder: (context, index) {
            final gesture = gestureService.gestures[index];
            return GestureCard(
              name: gesture.name,
              imagePath: gesture.imagePath,
              isAsset: gesture.isPredefined,
              onTap: () => onSendCommand(gesture.command),
              onLongPress: () =>
              gesture.isPredefined
                  ? null
                  : _showDeleteConfirmationDialog(context, gesture),
            );
          },
        );
      },
    );
  }
}