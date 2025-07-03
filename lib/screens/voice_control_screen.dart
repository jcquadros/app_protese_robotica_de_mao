import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import '../constants.dart'; // Importa nossas constantes

/// Tela que permite ao usuário controlar a mão robótica usando comandos de voz.
class VoiceControlScreen extends StatefulWidget {
  /// Callback para enviar o comando final interpretado.
  final Function(String) onSendCommand;
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
