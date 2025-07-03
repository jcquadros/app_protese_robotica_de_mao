import 'dart:async';
import 'package:flutter/material.dart';

/// Tela para o controle individual dos dedos de uma mão robótica.
class FingerControlScreen extends StatefulWidget {
  /// Callback que envia o comando formatado, ex: "INDICADOR:80".
  final Function(String) onSendCommand;

  const FingerControlScreen({super.key, required this.onSendCommand});

  @override
  State<FingerControlScreen> createState() => _FingerControlScreenState();
}

class _FingerControlScreenState extends State<FingerControlScreen> {
  /// Armazena o nome do dedo que está selecionado.
  String? _selectedFinger;

  /// Armazena o valor de dobra (0.0 a 100.0) para cada dedo.
  final Map<String, double> _fingerValues = {
    'Polegar': 0.0,
    'Indicador': 0.0,
    'Médio': 0.0,
    'Anelar': 0.0,
    'Mínimo': 0.0,
  };

  /// Timer para a lógica de "debounce", que evita o envio excessivo de comandos.
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel(); // Evita memory leaks.
    super.dispose();
  }

  /// Atualiza o valor do dedo e envia o comando após um atraso (debounce).
  void _onSliderChanged(double value) {
    if (_selectedFinger == null) return;

    setState(() {
      _fingerValues[_selectedFinger!] = value;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      String command = "${_selectedFinger!.toUpperCase()}:${value.toInt()}";
      widget.onSendCommand(command);
    });
  }

  /// Atualiza o dedo que está sendo controlado.
  void _onFingerSelected(String fingerName) {
    setState(() {
      _selectedFinger = fingerName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sliderValue = _fingerValues[_selectedFinger] ?? 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _selectedFinger ?? "Selecione um dedo para controlar",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: SizedBox(
            width: 300,
            height: 400,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(300, 400),
                  painter: _HandPainter(),
                ),
                _FingerControl(
                  name: 'Polegar',
                  top: 190,
                  left: 10,
                  height: 80,
                  width: 40,
                  value: _fingerValues['Polegar']!,
                  isSelected: _selectedFinger == 'Polegar',
                  onTap: () => _onFingerSelected('Polegar'),
                ),
                _FingerControl(
                  name: 'Indicador',
                  top: 50,
                  left: 60,
                  height: 100,
                  width: 40,
                  value: _fingerValues['Indicador']!,
                  isSelected: _selectedFinger == 'Indicador',
                  onTap: () => _onFingerSelected('Indicador'),
                ),
                _FingerControl(
                  name: 'Médio',
                  top: 20,
                  left: 110,
                  height: 130,
                  width: 40,
                  value: _fingerValues['Médio']!,
                  isSelected: _selectedFinger == 'Médio',
                  onTap: () => _onFingerSelected('Médio'),
                ),
                _FingerControl(
                  name: 'Anelar',
                  top: 30,
                  left: 160,
                  height: 120,
                  width: 40,
                  value: _fingerValues['Anelar']!,
                  isSelected: _selectedFinger == 'Anelar',
                  onTap: () => _onFingerSelected('Anelar'),
                ),
                _FingerControl(
                  name: 'Mínimo',
                  top: 50,
                  left: 210,
                  height: 100,
                  width: 40,
                  value: _fingerValues['Mínimo']!,
                  isSelected: _selectedFinger == 'Mínimo',
                  onTap: () => _onFingerSelected('Mínimo'),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Text(
            'Posição: ${sliderValue.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Slider(
          value: sliderValue,
          min: 0,
          max: 100,
          onChanged: _selectedFinger != null ? _onSliderChanged : null,
          label: sliderValue.toStringAsFixed(0),
          divisions: 100,
          activeColor: Colors.cyan,
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}

/// Desenha a forma estática de uma mão.
class _HandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final radius = Radius.circular(20);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(60, 170, 190, 150),
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(60, 50, 40, 100), radius),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(110, 20, 40, 130), radius),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(160, 30, 40, 120), radius),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(210, 50, 40, 100), radius),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(10, 190, 40, 80), radius),
      paint,
    );
  }

  /// Retorna `false` para otimização, pois o desenho da mão é estático e nunca muda.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Representa a área de toque e o indicador visual de cada dedo.
class _FingerControl extends StatelessWidget {
  final String name;
  final double top, left, height, width, value;
  final bool isSelected;
  final VoidCallback onTap;

  const _FingerControl({
    required this.name,
    required this.top,
    required this.left,
    required this.height,
    required this.width,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.cyan.withOpacity(0.5)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.cyanAccent : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Align(
              alignment: Alignment.bottomCenter,
              // A altura deste container representa visualmente o valor da "dobra" do dedo.
              child: Container(
                height: height * (value / 100),
                width: double.infinity,
                color: Colors.cyan.withOpacity(0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
