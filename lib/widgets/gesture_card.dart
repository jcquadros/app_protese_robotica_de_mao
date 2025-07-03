import 'package:flutter/material.dart';

/// Um widget reutilizável que exibe um cartão com a imagem e o nome de um gesto.
///
/// É projetado para ser usado em uma grade, sendo totalmente interativo ao toque.
class GestureCard extends StatelessWidget {
  /// O nome do gesto a ser exibido abaixo da imagem.
  final String name;
  /// O caminho para o arquivo de imagem do gesto (ex: 'assets/images/joia.png').
  final String imagePath;
  final VoidCallback onTap;

  const GestureCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Garante que o conteúdo (e o efeito de toque) seja cortado para
      // respeitar as bordas arredondadas do cartão.
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // InkWell adiciona o efeito de "ripple" (onda) ao toque.
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Expanded garante que a imagem preencha todo o espaço vertical
            // disponível no cartão, mantendo o texto na parte inferior.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(imagePath, fit: BoxFit.contain),
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