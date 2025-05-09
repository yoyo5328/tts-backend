import 'package:flutter/material.dart';

class TherapyGoalsScreen extends StatefulWidget {
  const TherapyGoalsScreen({super.key});

  @override
  State<TherapyGoalsScreen> createState() => _TherapyGoalsScreenState();
}

class _TherapyGoalsScreenState extends State<TherapyGoalsScreen> {
  final TextEditingController _expectationController = TextEditingController();

  Map<String, dynamic> genererProfilDepuisReponses(Map<String, String> reponses) {
    return {
      "nom": reponses["nom"] ?? "Patient",
      "sexe": reponses["sexe"] ?? "",
      "age": int.tryParse(reponses["age"] ?? "0") ?? 0,
      "religion": reponses["religion"] ?? "",
      "profession": reponses["profession"] ?? "",
      "objectifs": [reponses["expectation"] ?? ""],
      "niveau_anxiete": 6,
      "motivation": 5,
      "style_communication": "équilibré",
      "type": "Observateur"
    };
  }

  void _continueToVoiceTherapy(Map<String, String> previousAnswers) {
    final expectation = _expectationController.text.trim();

    final fullContext = {
      ...previousAnswers,
      'expectation': expectation,
    };

    final userProfile = genererProfilDepuisReponses(fullContext);

    Navigator.pushNamed(
      context,
      "/voice",
      arguments: userProfile,
    );
  }

  void _continueToChat(Map<String, String> previousAnswers) {
    final expectation = _expectationController.text.trim();

    final fullContext = {
      ...previousAnswers,
      'expectation': expectation,
    };

    Navigator.pushNamed(
      context,
      "/chat",
      arguments: fullContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previousAnswers =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>? ?? {};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("מה אתה מקווה להשיג בטיפול?")),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "במילים שלך, תאר/י מה אתה מקווה שיקרה בעקבות התהליך הטיפולי:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _expectationController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: "לדוגמה: אני רוצה להרגיש יותר ביטחון או להבין למה אני תקוע...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _continueToVoiceTherapy(previousAnswers),
                      icon: const Icon(Icons.record_voice_over),
                      label: const Text("קולית"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _continueToChat(previousAnswers),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("שיחה כתובה"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
