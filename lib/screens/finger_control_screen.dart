import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mao_robotica_app/models/hand_command.dart';
import 'package:mao_robotica_app/services/gesture_service.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

/// Tela para o controle individual dos dedos de uma mão robótica.
class FingerControlScreen extends StatefulWidget {
  final Function(HandCommand) onSendCommand;

  const FingerControlScreen({super.key, required this.onSendCommand});

  @override
  State<FingerControlScreen> createState() => _FingerControlScreenState();
}

class _FingerControlScreenState extends State<FingerControlScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  /// Armazena o valor de dobra (0.0 a 100.0) para cada dedo.
  final Map<String, double> _fingerValues = {
    'thumb': 0.0,
    'index': 0.0,
    'middle': 0.0,
    'ring': 0.0,
    'pinky': 0.0,
  };

  final Map<String, Map<String, double>> _fingerConfigs = {
    'thumb':  {'top': 190, 'left': 250, 'height': 80, 'width': 40},
    'index':  {'top': 50,  'left': 200, 'height': 100, 'width': 40},
    'middle': {'top': 20,  'left': 150, 'height': 130, 'width': 40},
    'ring':   {'top': 30,  'left': 100, 'height': 120, 'width': 40},
    'pinky':  {'top': 50,  'left': 50,  'height': 100, 'width': 40},
  };

  String? _draggingFinger;
  double _dragStartValue = 0.0;
  double _dragStartPosition = 0.0;

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Converte o mapa de valores (double) para um formato que HandCommand aceita (int)
  Map<String, int> _getCommandValues() {
    return _fingerValues.map((key, value) => MapEntry(key, value.toInt()));
  }

  /// Envia o comando com debounce. Chamado pelo controle circular.
  void _sendDebouncedCommand() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      final command = HandCommand.fromJson(_getCommandValues());
      widget.onSendCommand(command);
    });
  }

  void _onDragStart(String fingerName, DragStartDetails details) {
    setState(() {
      _draggingFinger = fingerName;
      _dragStartValue = _fingerValues[fingerName]!;
      _dragStartPosition = details.globalPosition.dy;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_draggingFinger == null) return;

    final dragDelta = _dragStartPosition - details.globalPosition.dy;
    // Sensibilidade: a cada 2 pixels arrastados, o valor muda 1 ponto. Ajuste se necessário.
    const sensitivity = 0.5;
    final valueDelta = dragDelta * sensitivity;

    // Calcula e limita o novo valor entre 0 e 100
    final newValue = (_dragStartValue + valueDelta).clamp(0.0, 100.0);

    setState(() {
      _fingerValues[_draggingFinger!] = newValue;
    });
    _sendDebouncedCommand();
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _draggingFinger = null;
    });
  }

  void _saveGesture() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar Gesto'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nome do gesto'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Salvar'),
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              FocusScope.of(context).unfocus();
              await Future.delayed(const Duration(milliseconds: 300));
              final imageBytes = await _screenshotController.capture(
                pixelRatio: 1.5,
              );
              if (imageBytes == null) return;

              final command = HandCommand.fromJson(_getCommandValues());
              final gestureService = Provider.of<GestureService>(
                context,
                listen: false,
              );

              await gestureService.addGesture(
                nameController.text,
                command,
                imageBytes,
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gesto "${nameController.text}" salvo!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Título/Instrução
                  Text(
                    "Pressione e arraste um dedo para controlar",
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildHandVisual(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // 4. Feedback Flutuante (continua funcionando sobre o Stack)
          if (_draggingFinger != null) _buildFloatingFeedback(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveGesture,
        icon: const Icon(Icons.save),
        label: const Text('Salvar Gesto'),
      ),
    );
  }

  /// Método auxiliar para construir o visual da mão.
  Widget _buildHandVisual() {
    return Screenshot(
      controller: _screenshotController,
      child: SizedBox(
        width: 300,
        height: 400,
        child: Container( 
          child: Stack(
            children: [
              CustomPaint(size: const Size(300, 400), painter: _HandPainter()),
              ..._fingerConfigs.entries.map((entry) {
                final fingerName = entry.key;
                final config = entry.value;
                return _FingerControl(
                  name: fingerName,
                  top: config['top']!,
                  left: config['left']!,
                  height: config['height']!,
                  width: config['width']!,
                  value: _fingerValues[fingerName]!,
                  onVerticalDragStart: (details) =>
                      _onDragStart(fingerName, details),
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// Método auxiliar para construir o feedback flutuante.
  Widget _buildFloatingFeedback() {
    String capitalizedFinger =
        "${_draggingFinger![0].toUpperCase()}${_draggingFinger!.substring(1)}";
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              "$capitalizedFinger: ${_fingerValues[_draggingFinger]!.toInt()}%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Desenha a forma estática de uma mão.
class _HandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors
          .white
      ..style = PaintingStyle.fill;

    final radius = Radius.circular(20);

    // Palma
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(50, 170, 190, 150), // Invertido
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      ),
      paint,
    );
    // Dedos (fundo)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(200, 50, 40, 100), radius),
      paint,
    ); // Index
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(150, 20, 40, 130), radius),
      paint,
    ); // Middle
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(100, 30, 40, 120), radius),
      paint,
    ); // Ring
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(50, 50, 40, 100), radius),
      paint,
    ); // Pinky
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(250, 190, 40, 80), radius),
      paint,
    ); // Thumb
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Representa a área de toque e o indicador visual de cada dedo.
class _FingerControl extends StatelessWidget {
  final String name;
  final double top, left, height, width, value;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  const _FingerControl({
    required this.name,
    required this.top,
    required this.left,
    required this.height,
    required this.width,
    required this.value,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onVerticalDragStart: onVerticalDragStart,
        onVerticalDragUpdate: onVerticalDragUpdate,
        onVerticalDragEnd: onVerticalDragEnd,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30, width: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: height * (value / 100),
                width: double.infinity,
                color: Colors.cyan.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
