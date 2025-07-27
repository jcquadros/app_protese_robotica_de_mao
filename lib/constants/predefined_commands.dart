import '../models/hand_command.dart';

/// Lista de dados que define cada gesto, incluindo nome, imagem e o comando a ser enviado.
final List<Map<String, dynamic>> predefinedGestures = [
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