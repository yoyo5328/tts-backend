from flask import Flask, request, jsonify
import os
import openai
from google.cloud import texttospeech
from dotenv import load_dotenv
import base64

load_dotenv()

openai.api_key = os.getenv("OPENAI_API_KEY")

# Configure Google TTS
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "gcloud_key.json"

app = Flask(__name__)

@app.route("/voice_decision", methods=["POST"])
def voice_decision():
    data = request.get_json()
    message = data.get("message", "")
    profil = data.get("profil", {})

    if not message:
        return jsonify({"error": "Message manquant"}), 400

    # 1. Traitement avec OpenAI
    completion = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "Tu es un thérapeute bienveillant."},
            {"role": "user", "content": message}
        ]
    )
    response_text = completion["choices"][0]["message"]["content"]

    # 2. Générer l’audio avec Google TTS
    client = texttospeech.TextToSpeechClient()
    synthesis_input = texttospeech.SynthesisInput(text=response_text)

    voice = texttospeech.VoiceSelectionParams(
        language_code="he-IL", name="he-IL-Wavenet-A"
    )
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.MP3
    )

    response = client.synthesize_speech(
        input=synthesis_input, voice=voice, audio_config=audio_config
    )

    audio_base64 = base64.b64encode(response.audio_content).decode("utf-8")
    return jsonify({"texte": response_text, "audioContent": audio_base64})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)


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
