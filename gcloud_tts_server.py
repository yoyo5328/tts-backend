import os
from flask import Flask, request, jsonify
from google.cloud import texttospeech

# 🔐 Générer le fichier à partir de la variable Render
if "GOOGLE_APPLICATION_CREDENTIALS_JSON" in os.environ:
    with open("google_key.json", "w") as f:
        f.write(os.environ["GOOGLE_APPLICATION_CREDENTIALS_JSON"])
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = os.path.abspath("google_key.json")

app = Flask(__name__)

@app.route("/gcloud_tts", methods=["POST"])
def gcloud_tts():
    data = request.get_json()
    text = data.get("text", "")
    voice_name = data.get("voice", "he-IL-Wavenet-A")

    client = texttospeech.TextToSpeechClient()

    synthesis_input = texttospeech.SynthesisInput(text=text)
    voice = texttospeech.VoiceSelectionParams(
        language_code="he-IL",
        name=voice_name
    )
    audio_config = texttospeech.AudioConfig(audio_encoding=texttospeech.AudioEncoding.MP3)

    response = client.synthesize_speech(
        input=synthesis_input,
        voice=voice,
        audio_config=audio_config
    )

    audio_base64 = response.audio_content
    return jsonify({"audioContent": audio_base64.decode("ISO-8859-1")})

if __name__ == "__main__":
    from waitress import serve
    serve(app, host="0.0.0.0", port=8080)
