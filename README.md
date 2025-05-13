# PsyAI - Backend Vocal avec GPT et Google TTS

Ce projet constitue le **backend vocal** de l’application **PsyAI**, un assistant thérapeutique intelligent développé en Flutter. Il repose sur l'utilisation de :

- 🧠 [OpenAI GPT-3.5](https://platform.openai.com/docs/guides/gpt)
- 🗣️ [Google Cloud Text-to-Speech](https://cloud.google.com/text-to-speech)
- 🔁 [Flask (Python)](https://flask.palletsprojects.com/)
- ☁️ Déploiement sur [Render](https://render.com)

---

## 🔧 Fonctionnalité principale

L'API `/voice_decision` reçoit un message vocal converti en texte, le transmet à OpenAI GPT pour analyse et réponse, puis convertit la réponse textuelle en audio via Google TTS.

---

## 📁 Structure du projet

```
backend/
├── main.py                # Point d'entrée principal du backend
├── requirements.txt       # Dépendances Python
├── render.yaml            # Configuration Render
├── gcloud_tts_server.py   # Serveur TTS (optionnel ou séparé)
```

---

## 🚀 Lancer le projet en local

1. Crée un environnement virtuel :
   ```bash
   python -m venv venv
   source venv/bin/activate  # (ou venv\Scripts\activate sur Windows)
   ```

2. Installe les dépendances :
   ```bash
   pip install -r requirements.txt
   ```

3. Exporte ta clé Google Cloud TTS :
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="gcloud_key.json"
   ```

4. Lance le serveur Flask :
   ```bash
   python main.py
   ```

---

## 🧪 Tester l’API vocalement

```bash
curl -X POST https://psyyai.onrender.com/voice_decision \
  -H "Content-Type: application/json" \
  -d '{"message": "שלום", "profil": {"nom": "יונתן"}}'
```

> Réponse attendue : texte + audio base64

---

## 📦 Déploiement Render

Le projet est déployé automatiquement sur [Render](https://render.com) grâce au fichier `render.yaml` :

```yaml
services:
  - type: web
    name: psyai-backend
    runtime: python
    buildCommand: "pip install -r requirements.txt"
    startCommand: "python main.py"
    rootDir: backend
```

---

## 📌 Auteurs

Développé par Israel Hai — Projet **PsyAI**
