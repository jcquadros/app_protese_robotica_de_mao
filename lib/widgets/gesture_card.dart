import 'package:flutter/material.dart';
import 'dart:io';
/// Um widget reutilizável que exibe um cartão com a imagem e o nome de um gesto.
///
/// É projetado para ser usado em uma grade, sendo totalmente interativo ao toque.
class GestureCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; 
  final bool isAsset;

  const GestureCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.onTap,
    this.onLongPress, 
    this.isAsset = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = isAsset
        ? Image.asset(imagePath, fit: BoxFit.contain)
        : Image.file(File(imagePath), fit: BoxFit.contain);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress, // NOVO: Conectando o callback ao InkWell
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Expanded garante que a imagem preencha todo o espaço vertical
            // disponível no cartão, mantendo o texto na parte inferior.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: imageWidget,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}