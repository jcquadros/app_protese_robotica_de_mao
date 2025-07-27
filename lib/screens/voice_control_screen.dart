import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mao_robotica_app/constants/predefined_commands.dart';
import 'package:mao_robotica_app/models/hand_command.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import '../constants/envs.dart';

/// Tela que permite ao usuário controlar a mão robótica usando comandos de voz.
class VoiceControlScreen extends StatefulWidget {
  /// Callback para enviar o comando final interpretado.
  final Function(HandCommand) onSendCommand;
  const VoiceControlScreen({super.key, required this.onSendCommand});

  @override
  State<VoiceControlScreen> createState() => _VoiceControlScreenState();
}

class _VoiceControlScreenState extends State<VoiceControlScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _statusText = "Pressione o microfone para dar um comando";
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastWords = "";

  final _jsonGestures = jsonEncode(predefinedGestures.map((gesture) => {
    'name': gesture['name'],
    'command': gesture['command'],
  }).toList());

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// Inicializa o serviço de reconhecimento de voz.
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

  /// Alterna entre iniciar e parar a escuta do microfone.
  void _toggleRecording() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  /// Inicia a escuta do microfone e define os callbacks de resultado.
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
                _isProcessing = true;
                _statusText = "Processando: \"$transcribedText\"";
              });
            }
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

  /// Para a escuta do microfone.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      _statusText = "Pressione o microfone para dar um comando";
    });
  }

  /// Envia o texto para a API do Gemini para interpretação.
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
      Você é um assistente que recebe um comando de voz relacionado a gestos de mão e deve retornar apenas o nome de um dos seguintes gestos:.
      
      $_jsonGestures
      
      - 100 significa o dedo totalmente fechado
      - 0 significa o dedo totalmente estendido
      
      Com base na frase abaixo, retorne o nome do comando que está mais relacionado:
          
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

        String responseString = data['candidates'][0]['content']['parts'][0]['text'].trim().replaceAll("json", "").replaceAll("`", "");

        HandCommand command = predefinedGestures.firstWhere((gesture) => gesture['name'] == responseString, orElse: () => { 'command': HandCommand() })['command'];

        widget.onSendCommand(command);
      } else {
        _statusText = "Erro na API do Gemini: ${response.body}";
      }
    } catch (e) {
      _statusText = "Erro de conexão: $e";
    }

    if(mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
