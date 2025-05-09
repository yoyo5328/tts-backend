from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route("/voice_decision", methods=["POST"])
def voice_decision():
    data = request.get_json()
    message = data.get("message", "")
    profil = data.get("profil", {})
    response = f"אני מבין אותך: {message}. תודה ששיתפת אותי."
    return jsonify({"texte": response})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
