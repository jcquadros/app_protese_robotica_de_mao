import 'package:mao_robotica_app/models/hand_command.dart';

class Gesture {
  final String id;
  final String name;
  final bool isPredefined;
  final String imagePath; // Caminho para a imagem salva no dispositivo
  final HandCommand command;

  Gesture({
    required this.id,
    required this.name,
    this.isPredefined = true,
    required this.imagePath,
    required this.command,
  });

  // Métodos para serialização/desserialização em JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isPredefined': isPredefined,
    'imagePath': imagePath,
    'command': command.toJson(),
  };

  factory Gesture.fromJson(Map<String, dynamic> json) => Gesture(
    id: json['id'],
    name: json['name'],
    imagePath: json['imagePath'],
    command: HandCommand.fromJson(json['command']),
  );
}
