import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;

// --- Blueprint da Comunicação ---
// Estes UUIDs DEVEM ser os mesmos que estão no código do ESP32.
const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

// --- Configuração da API do Gemini ---
// TODO: Substitua 'SUA_CHAVE_DE_API_AQUI' pela chave que você obteve do Google AI Studio.
const String GEMINI_API_KEY = "AIzaSyCLzrm9W6PJFMbrgYeG4OSD4Uj1heF_ZaM";
const String GEMINI_API_URL =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$GEMINI_API_KEY";

// Variável global para armazenar a característica alvo para escrita.
BluetoothCharacteristic? targetCharacteristic;
// Variável global para armazenar o dispositivo conectado.
BluetoothDevice? connectedDevice;
// Stream para monitorar o estado da conexão.
Stream<BluetoothConnectionState> connectionStateStream = Stream.empty();

void main() {
  runApp(const MyApp());
}

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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Função para enviar dados via BLE
  // void _sendCommand(String command) {
  //   if (targetCharacteristic != null) {
  //     // Converte o comando String para uma lista de bytes (UTF-8)
  //     List<int> bytes = utf8.encode(command);
  //     // Escreve os bytes na característica
  //     targetCharacteristic!.write(bytes);
  //     print("Comando enviado: $command");
  //   } else {
  //     print("Nenhuma característica alvo encontrada para enviar comando.");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Dispositivo não conectado!')),
  //     );
  //   }
  // }

  void _sendCommand(String command) {
    // Apenas simulamos o envio, mostrando a notificação e o log.
    print("Simulando envio do comando: $command");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Simulando envio: $command')));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Controle Mão Robótica'),
          // Ícone de status do Bluetooth
          actions: [
            StreamBuilder<BluetoothConnectionState>(
              stream: connectionStateStream,
              initialData: BluetoothConnectionState.disconnected,
              builder: (c, snapshot) {
                IconData icon;
                Color color;
                if (snapshot.data == BluetoothConnectionState.connected) {
                  icon = Icons.bluetooth_connected;
                  color = Colors.lightBlueAccent;
                } else {
                  icon = Icons.bluetooth_disabled;
                  color = Colors.grey;
                }
                return IconButton(
                  icon: Icon(icon, color: color),
                  onPressed: () {
                    // Navega para a tela de conexão
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BluetoothConnectionScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sign_language), text: 'Gestos'),
              Tab(icon: Icon(Icons.fingerprint), text: 'Dedos'),
              Tab(icon: Icon(Icons.mic), text: 'Voz'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Passando a função de enviar comando para as telas filhas
            GesturesScreen(onSendCommand: _sendCommand),
            FingerControlScreen(onSendCommand: _sendCommand),
            VoiceControlScreen(onSendCommand: _sendCommand),
          ],
        ),
      ),
    );
  }
}

// --- Tela de Gestos (Modificada para enviar comando) ---
class GesturesScreen extends StatelessWidget {
  final Function(String) onSendCommand;
  GesturesScreen({super.key, required this.onSendCommand});

  final List<Map<String, String>> gestures = [
    {
      'name': 'Faz o L',
      'image': 'assets/images/fazoele.png',
      'command': 'FAZOELE',
    },
    {'name': 'Joia', 'image': 'assets/images/joia.png', 'command': 'JOIA'},
    {'name': 'Paz', 'image': 'assets/images/paz.png', 'command': 'PAZ'},
    {'name': 'Rock', 'image': 'assets/images/rock.png', 'command': 'ROCK'},
    {'name': 'OK', 'image': 'assets/images/ok.png', 'command': 'OK'},
    {
      'name': 'Apontar',
      'image': 'assets/images/apontar.png',
      'command': 'APONTAR',
    },
    {'name': 'Parar', 'image': 'assets/images/parar.png', 'command': 'PARAR'},
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
          onTap: () =>
              onSendCommand(gesture['command']!), // Envia o comando específico
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

// --- TELA DE CONTROLE DE VOZ (COM LÓGICA DO GEMINI INTEGRADA) ---
class VoiceControlScreen extends StatefulWidget {
  final Function(String) onSendCommand;
  const VoiceControlScreen({super.key, required this.onSendCommand});

  @override
  State<VoiceControlScreen> createState() => _VoiceControlScreenState();
}

class _VoiceControlScreenState extends State<VoiceControlScreen> {
  // Variáveis de estado
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _statusText = "Pressione o microfone para dar um comando";
  bool _isListening = false;
  bool _isProcessing = false; // Estado para feedback durante a chamada da API
  String _lastWords = "";

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  // Inicializa o serviço de reconhecimento de voz.
  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize();
    } catch (e) {
      print("Exceção ao inicializar o reconhecimento de voz: $e");
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Função principal que controla o botão.
  void _toggleRecording() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // Inicia a escuta do microfone.
  void _startListening() async {
    if (!_speechEnabled) return;
    
    setState(() {
      _isListening = true;
      _statusText = "Ouvindo...";
      _lastWords = "";
    });

    _speechToText.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });

        if (result.finalResult) {
          String transcribedText = result.recognizedWords;
          if (transcribedText.isNotEmpty) {
            if(mounted) {
              setState(() {
                _isListening = false;
                _isProcessing = true; // Inicia o estado de processamento
                _statusText = "Processando: \"$transcribedText\"";
              });
            }
            // Chama a função que usa o Gemini
            _interpretAndSendCommand(transcribedText);
          } else {
            if (mounted) {
              setState(() {
                _isListening = false;
                _statusText = "Não ouvi nada. Tente novamente.";
              });
            }
          }
        }
      },
      localeId: 'pt_BR',
      listenFor: const Duration(seconds: 30),
    );
  }

  // Para a escuta do microfone.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      // O resultado será processado pelo callback onResult
    });
  }

  // Envia o texto para a API do Gemini e depois o comando para o ESP32.
  Future<void> _interpretAndSendCommand(String text) async {
    if (GEMINI_API_KEY == "SUA_CHAVE_DE_API_AQUI") {
       if(mounted) {
         setState(() {
           _statusText = "ERRO: Configure sua chave de API do Gemini!";
           _isProcessing = false;
         });
       }
       return;
    }

    final String prompt = """
      Você é um controlador de uma mão robótica. Sua única função é converter uma frase em um comando específico.
      Os comandos de gestos válidos são: JOIA, PAZ, ROCK, OK, APONTAR, PARAR, FAZOELE.
      Os comandos de dedos individuais seguem o formato NOME_DEDO:VALOR, onde o valor é de 0 a 100. Os nomes dos dedos são: POLEGAR, INDICADOR, MEDIO, ANELAR, MINIMO.
      Exemplos: "Dobre o dedo indicador até a metade" -> INDICADOR:50. "Estique o polegar" -> POLEGAR:0. "Sinal de rock" -> ROCK.
      Responda APENAS com o comando. Se não entender a frase, responda com "UNKNOWN".
      Frase para converter: "$text"
    """;

    try {
      final response = await http.post(
        Uri.parse(GEMINI_API_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String command = data['candidates'][0]['content']['parts'][0]['text'].trim();
        
        if (command != "UNKNOWN") {
          widget.onSendCommand(command);
          _statusText = "Comando '$command' enviado!";
        } else {
          _statusText = "Não entendi o comando. Tente novamente.";
        }
      } else {
        _statusText = "Erro na API do Gemini: ${response.body}";
      }
    } catch (e) {
      _statusText = "Erro de conexão: $e";
    }

    if(mounted) {
      setState(() {
        _isProcessing = false; // Finaliza o processamento
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lógica para definir a aparência do botão com base nos 3 estados
    IconData icon;
    Color buttonColor;
    if (_isListening) {
      icon = Icons.stop;
      buttonColor = Colors.red.shade700;
    } else if (_isProcessing) {
      icon = Icons.hourglass_top;
      buttonColor = Colors.amber.shade700;
    } else {
      icon = Icons.mic_none;
      buttonColor = Colors.cyan.shade700;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (_lastWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(
                '"$_lastWords"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.white70),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            // O botão fica desabilitado durante o processamento
            onPressed: _isProcessing ? null : _toggleRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              disabledBackgroundColor: Colors.amber.shade900,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(40),
            ),
            child: Icon(icon, color: Colors.white, size: 60),
          ),
        ],
      ),
    );
  }
}
// --- Tela de Controle de Dedos (Modificada para enviar comando) ---
class FingerControlScreen extends StatefulWidget {
  final Function(String) onSendCommand;
  const FingerControlScreen({super.key, required this.onSendCommand});

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

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    if (_selectedFinger == null) return;

    setState(() {
      _fingerValues[_selectedFinger!] = value;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Este código dentro do Timer só executa quando o usuário para de mover o slider.
      String command = "${_selectedFinger!.toUpperCase()}:${value.toInt()}";
      widget.onSendCommand(command);
    });
  }

  void _onFingerSelected(String fingerName) {
    setState(() {
      _selectedFinger = fingerName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sliderValue = _selectedFinger != null
        ? _fingerValues[_selectedFinger!]!
        : 0.0;

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
                top: 170,
                left: 0,
                height: 100,
                width: 45,
                value: _fingerValues['Polegar']!,
                isSelected: _selectedFinger == 'Polegar',
                onTap: () => _onFingerSelected('Polegar'),
              ),
              _FingerControl(
                name: 'Indicador',
                top: 44,
                left: 54,
                height: 160,
                width: 44,
                value: _fingerValues['Indicador']!,
                isSelected: _selectedFinger == 'Indicador',
                onTap: () => _onFingerSelected('Indicador'),
              ),
              _FingerControl(
                name: 'Médio',
                top: 30,
                left: 108,
                height: 170,
                width: 45,
                value: _fingerValues['Médio']!,
                isSelected: _selectedFinger == 'Médio',
                onTap: () => _onFingerSelected('Médio'),
              ),
              _FingerControl(
                name: 'Anelar',
                top: 40,
                left: 167,
                height: 160,
                width: 45,
                value: _fingerValues['Anelar']!,
                isSelected: _selectedFinger == 'Anelar',
                onTap: () => _onFingerSelected('Anelar'),
              ),
              _FingerControl(
                name: 'Mínimo',
                top: 105,
                left: 220,
                height: 110,
                width: 45,
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
        const SizedBox(height: 60),
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

// --- NOVA TELA DE CONEXÃO BLUETOOTH ---
class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({super.key});

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      isScanning = true;
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults
        .listen((results) {
          setState(() {
            // Filtra para mostrar apenas dispositivos com nome
            scanResults = results
                .where((r) => r.device.platformName.isNotEmpty)
                .toList();
          });
        })
        .onDone(() {
          setState(() {
            isScanning = false;
          });
        });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await device.connect();
    // Atualiza a stream de conexão para a UI principal
    setState(() {
      connectionStateStream = device.connectionState;
      connectedDevice = device;
    });

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == SERVICE_UUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            setState(() {
              targetCharacteristic = characteristic;
            });
            // Conexão bem sucedida, volta para a tela anterior
            Navigator.of(context).pop();
            return;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar Dispositivo'),
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.stop : Icons.search),
            onPressed: isScanning
                ? () => FlutterBluePlus.stopScan()
                : _startScan,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: scanResults.length,
        itemBuilder: (context, index) {
          final result = scanResults[index];
          return ListTile(
            title: Text(result.device.platformName),
            subtitle: Text(result.device.remoteId.toString()),
            trailing: ElevatedButton(
              child: const Text('Conectar'),
              onPressed: () => _connectToDevice(result.device),
            ),
          );
        },
      ),
    );
  }
}
