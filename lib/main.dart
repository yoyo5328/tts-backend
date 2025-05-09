import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 🧩 fichier généré par flutterfire
import 'dart:convert';

import 'screens/therapy_goals_screen.dart';
import 'screens/therapy_voice_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PsyAIApp());
}

class PsyAIApp extends StatelessWidget {
  const PsyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PsyAI',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
        '/goals': (context) => const TherapyGoalsScreen(),
        '/voice': (context) => const TherapyVoiceScreen(
              userProfile: {
                "nom": "יונתן",
                "age": 30,
                "emotion": "שמחה",
                "besoin": "הבנה",
                "valeur": "קבלה",
                "intention": "להירגע"
              },
            ),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PsyAI")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/chat'),
              child: const Text("💬 Discussion GPT"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/goals'),
              child: const Text("🎯 Objectifs"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/voice'),
              child: const Text("🎙️ Thérapie vocale"),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  String _response = "";
  bool _isLoading = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _textFromVoice = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => debugPrint('🔊 Status: $val'),
      onError: (val) => debugPrint('❌ Error: $val'),
    );

    if (!available) {
      debugPrint("🎤 Micro non disponible.");
      return;
    }

    setState(() => _isListening = true);

    _speech.listen(
      localeId: 'he_IL',
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 3),
      onResult: (val) => setState(() {
        _textFromVoice = val.recognizedWords;
        _controller.text = _textFromVoice;
      }),
    );
  }

  Future<void> sendMessageToGPT(String message) async {
    const apiKey = "TON_API_KEY"; // 🛑 À remplacer

    setState(() => _isLoading = true);

    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content": "אתה פסיכולוג רגיש שמדבר בעברית ומבין את האדם שמולך. ענה ברגישות ובתמיכה."
          },
          {
            "role": "user",
            "content": message
          }
        ]
      }),
    );

    final data = jsonDecode(response.body);
    setState(() {
      _isLoading = false;
      _response = data["choices"][0]["message"]["content"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("פסיכולוג אישי")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _controller,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: "מה עובר עליך?",
              ),
              onSubmitted: (value) {
                sendMessageToGPT(value);
                _controller.clear();
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: startListening,
              icon: const Icon(Icons.mic),
              label: const Text("🎤 דבר"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    _response,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
          ],
        ),
      ),
    );
  }
}
