from flask import Flask, request, jsonify
import os
import base64
from dotenv import load_dotenv
from google.cloud import texttospeech
from openai import OpenAI  # nouvelle API

load_dotenv()

# Initialiser le client OpenAI
openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Clé Google Cloud
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "gcloud_key.json"

app = Flask(__name__)

@app.route("/voice_decision", methods=["POST"])
def voice_decision():
    data = request.get_json()
    message = data.get("message", "")
    profil = data.get("profil", {})

    if not message:
        return jsonify({"error": "Message manquant"}), 400

    # 1. Appel à GPT (nouvelle syntaxe OpenAI v1)
    chat_response = openai_client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "Tu es un thérapeute bienveillant."},
            {"role": "user", "content": message}
        ]
    )
    response_text = chat_response.choices[0].message.content

    # 2. Google TTS
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
