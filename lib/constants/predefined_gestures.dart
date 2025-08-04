import '../models/gesture.dart';
import '../models/hand_command.dart';

// Lista de dados que define cada gesto, incluindo nome, imagem e o comando a ser enviado.
final List<Gesture> predefinedGestures = [
  Gesture(
    id: 'gesture_0',
    name: 'Faz o L',
    imagePath: 'assets/images/fazoele.png',
    command: HandCommand(
      thumb: 0,
      index: 0,
      middle: 100,
      ring: 100,
      pinky: 100,
    ),
  ),
  Gesture(
    id: 'gesture_1',
    name: 'Joia',
    imagePath: 'assets/images/joia.png',
    command: HandCommand(
      thumb: 0,
      index: 100,
      middle: 100,
      ring: 100,
      pinky: 100,
    ),
  ),
  Gesture(
    id: 'gesture_2',
    name: 'Paz',
    imagePath: 'assets/images/paz.png',
    command: HandCommand(
      thumb: 100,
      index: 0,
      middle: 0,
      ring: 100,
      pinky: 100,
    ),
  ),
  Gesture(
    id: 'gesture_3',
    name: 'Ok',
    imagePath: 'assets/images/ok.png',
    command: HandCommand(
      thumb: 0,
      index: 0,
      middle: 100,
      ring: 100,
      pinky: 100,
    ),
  ),
  Gesture(
    id: 'gesture_4',
    name: 'Rock',
    imagePath: 'assets/images/rock.png',
    command: HandCommand(
      thumb: 100,
      index: 0,
      middle: 100,
      ring: 100,
      pinky: 0,
    ),
  ),
  Gesture(
    id: 'gesture_5',
    name: 'Apontar',
    imagePath: 'assets/images/apontar.png',
    command: HandCommand(
      thumb: 100,
      index: 0,
      middle: 100,
      ring: 100,
      pinky: 100,
    ),
  ),
  Gesture(
    id: 'gesture_6',
    name: 'Fechar',
    imagePath: 'assets/images/aberta.png',
    command: HandCommand(
      thumb: 100,
      index: 100,
      middle: 100,
      ring: 100,
      pinky: 100,
    ),
  ),
  Gesture(
    id: 'gesture_7',
    name: 'Abrir',
    imagePath: 'assets/images/aberta.png',
    command: HandCommand(thumb: 0, index: 0, middle: 0, ring: 0, pinky: 0),
  ),
];
