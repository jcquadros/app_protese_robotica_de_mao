import 'package:flutter/material.dart';

// A função main é o ponto de entrada do seu aplicativo.
void main() {
  runApp(const MyApp());
}

// MyApp é o widget raiz. Ele define as configurações gerais do app.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Mão Robótica',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

// MainScreen continua sendo a nossa tela principal com as abas.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Controle Mão Robótica'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sign_language), text: 'Gestos'),
              Tab(icon: Icon(Icons.fingerprint), text: 'Dedos'),
              Tab(icon: Icon(Icons.mic), text: 'Voz'),
            ],
          ),
        ),
        // CORREÇÃO: Adicionando a FingerControlScreen para que o número de
        // abas (3) corresponda ao número de telas.
        body: TabBarView(
          children: [
            GesturesScreen(),
            FingerControlScreen(), // Esta tela estava faltando
            VoiceControlScreen(),
          ],
        ),
      ),
    );
  }
}

// --- TELA DE GESTOS (Sem alterações) ---
class GesturesScreen extends StatelessWidget {
  GesturesScreen({super.key});

  final List<Map<String, String>> gestures = [
    {'name': 'Faz o L', 'image': 'assets/images/fazoele.png'},
    {'name': 'Joia', 'image': 'assets/images/joia.png'},
    {'name': 'Paz', 'image': 'assets/images/paz.png'},
    {'name': 'Rock', 'image': 'assets/images/rock.png'},
    {'name': 'OK', 'image': 'assets/images/ok.png'},
    {'name': 'Apontar', 'image': 'assets/images/apontar.png'},
    {'name': 'Parar', 'image': 'assets/images/parar.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.85,
      ),
      itemCount: gestures.length,
      itemBuilder: (context, index) {
        final gesture = gestures[index];
        return GestureCard(
          name: gesture['name']!,
          imagePath: gesture['image']!,
          onTap: () {
            print('Gesto selecionado: ${gesture['name']}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Enviando comando: ${gesture['name']}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }
}

class GestureCard extends StatelessWidget {
  final String name;
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
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- TELA DE CONTROLE DE VOZ (Sem alterações) ---
class VoiceControlScreen extends StatefulWidget {
  const VoiceControlScreen({super.key});

  @override
  State<VoiceControlScreen> createState() => _VoiceControlScreenState();
}

class _VoiceControlScreenState extends State<VoiceControlScreen> {
  bool _isRecording = false;
  String _statusText = "Pressione o microfone para iniciar a gravação";

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _statusText = "Ouvindo... Pressione novamente para parar.";
        print("Iniciando a gravação...");
      } else {
        _statusText = "Gravação finalizada! Pressione para gravar novamente.";
        print("Parando a gravação...");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _toggleRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording ? Colors.red.shade700 : Colors.cyan.shade700,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(40),
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 60,
            ),
          ),
        ],
      ),
    );
  }
}


// --- TELA DE CONTROLE DE DEDOS (Com correções) ---
class FingerControlScreen extends StatefulWidget {
  const FingerControlScreen({super.key});

  @override
  State<FingerControlScreen> createState() => _FingerControlScreenState();
}

class _FingerControlScreenState extends State<FingerControlScreen> {
  String? _selectedFinger; 
  final Map<String, double> _fingerValues = {
    'Polegar': 0.0,
    'Indicador': 0.0,
    'Médio': 0.0,
    'Anelar': 0.0,
    'Mínimo': 0.0,
  };

  void _onSliderChanged(double value) {
    if (_selectedFinger != null) {
      setState(() {
        _fingerValues[_selectedFinger!] = value;
        print('$_selectedFinger: ${value.toStringAsFixed(0)}%');
      });
    }
  }

  void _onFingerSelected(String fingerName) {
    setState(() {
      _selectedFinger = fingerName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sliderValue = _selectedFinger != null ? _fingerValues[_selectedFinger!]! : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _selectedFinger ?? "Selecione um dedo para controlar",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/images/mao_fundo_transparente.png'),

              // ATUALIZAÇÃO: Novos valores de posição e tamanho, calculados a partir das suas imagens.
              _FingerControl(
                name: 'Polegar',
                top: 190, left: 0, height: 100, width: 45,
                value: _fingerValues['Polegar']!,
                isSelected: _selectedFinger == 'Polegar',
                onTap: () => _onFingerSelected('Polegar'),
              ),
              _FingerControl(
                name: 'Indicador',
                top: 64, left: 54, height: 160, width: 44,
                value: _fingerValues['Indicador']!,
                isSelected: _selectedFinger == 'Indicador',
                onTap: () => _onFingerSelected('Indicador'),
              ),
              _FingerControl(
                name: 'Médio',
                top: 50, left: 108, height: 170, width: 45,
                value: _fingerValues['Médio']!,
                isSelected: _selectedFinger == 'Médio',
                onTap: () => _onFingerSelected('Médio'),
              ),
              _FingerControl(
                name: 'Anelar',
                top: 60, left: 167, height: 160, width: 45,
                value: _fingerValues['Anelar']!,
                isSelected: _selectedFinger == 'Anelar',
                onTap: () => _onFingerSelected('Anelar'),
              ),
              _FingerControl(
                name: 'Mínimo',
                top: 125, left: 220, height: 110, width: 45,
                value: _fingerValues['Mínimo']!,
                isSelected: _selectedFinger == 'Mínimo',
                onTap: () => _onFingerSelected('Mínimo'),
              ),
            ],
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
        const SizedBox(height: 20),
      ],
    );
  }
}

// Widget customizado para representar a área de toque e o visual de cada dedo.
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
            color: isSelected ? Colors.cyan.withOpacity(0.5) : Colors.transparent,
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