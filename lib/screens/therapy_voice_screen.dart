import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class TherapyVoiceScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const TherapyVoiceScreen({super.key, required this.userProfile});

  @override
  State<TherapyVoiceScreen> createState() => _TherapyVoiceScreenState();
}

class _TherapyVoiceScreenState extends State<TherapyVoiceScreen>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  bool _isLoading = false;
  String _textFromVoice = "";
  late AnimationController _animationController;
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _tts.setLanguage("he-IL");
    _tts.setVoice({
      'name': 'Google עברית',
      'locale': 'he-IL',
    });
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.74);

    _tts.getVoices.then((voices) {
      print("🔣 VOIX DISPONIBLES : $voices");
    });

    _tts.setCompletionHandler(() {
      startListening();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      speak("ספר לי מה אתה עובר עכשיוו.");
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    player.dispose();
    super.dispose();
  }

  void startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('🎧 Status: $val'),
      onError: (val) => print('❌ Error: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: 'he_IL',
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 4),
        onResult: (val) {
          setState(() => _textFromVoice = val.recognizedWords);
          if (val.finalResult && val.recognizedWords.trim().isNotEmpty) {
            stopListening();
            sendToBackend(_textFromVoice);
          }
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> sendToBackend(String message) async {
    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse("https://psyai-backend-v2um.onrender.com/voice_decision");
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": message,
          "profil": widget.userProfile,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String reply = data["texte"] ?? "תודה שדיברת איתי.";
        await sendToGCloudTTS(reply);
      } else {
        speak("אירעה שגיאה בעיבוד הנתונים.");
      }
    } catch (e) {
      speak("לא הצלחתי לשלוח את ההודעה.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> sendToGCloudTTS(String message) async {
    const endpoint = "https://tts-backend-02p3.onrender.com";

    final res = await http.post(
      Uri.parse(endpoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "text": message,
        "voice": "he-IL-Wavenet-A",
      }),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final base64Audio = body["audioContent"];
      final audioBytes = base64Decode(base64Audio);

      if (kIsWeb) {
        print("🎧 Lecture de bytes audio non supportée sur Web.");
        // À remplacer par <audio> HTML si nécessaire
      } else {
        final audioFile = await _writeBytesToTempFile(audioBytes);
        await player.setUrl(audioFile.path);
        await player.play();
      }
    } else {
      print("Erreur TTS: ${res.body}");
    }
  }

  Future<File> _writeBytesToTempFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/tts_audio.mp3');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> speak(String text) async {
    print("🗣️ GPT : $text");
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E1A47),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 32.0),
              child: Text(
                "תשתף אותי על מה שעובר עלייך",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
            const Spacer(),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: 200 + (_animationController.value * 20),
                        height: 200 + (_animationController.value * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.cyanAccent.withOpacity(0.1),
                              Colors.blueAccent.withOpacity(0.05)
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: _isListening ? stopListening : startListening,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00E5FF),
                            Color(0xFF00ACC1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Positioned(
                      bottom: 40,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
