import 'package:mao_robotica_app/models/hand_command.dart';

class CustomGesture {
  final String id;
  final String name;
  final String imagePath; // Caminho para a imagem salva no dispositivo
  final HandCommand command;

  CustomGesture({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.command,
  });

  // Métodos para serialização/desserialização em JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'command': command.toJson(),
  };

  factory CustomGesture.fromJson(Map<String, dynamic> json) => CustomGesture(
    id: json['id'],
    name: json['name'],
    imagePath: json['imagePath'],
    command: HandCommand.fromJson(json['command']),
  );
}