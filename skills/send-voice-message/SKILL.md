---
name: send-voice-message
description: Turn one of YOUR OWN assistant messages from the conversation into a spoken-audio (voice) note with ElevenLabs and send it on Telegram. By default it speaks the LAST assistant message in the history; it is NOT for the user to dictate fresh text. Use this whenever the user asks to hear a reply as audio, "manda em áudio", "grava um áudio", "send as voice", "read that out loud", with or without naming the tooling. If the user points at a specific earlier message, voice that one instead.
---

# Send Voice Message (ElevenLabs → Telegram)

This skill turns text into a natural-sounding voice note and delivers it to a Telegram chat. It uses ElevenLabs for high-quality multilingual TTS (great in PT-BR), converts the result to the Opus/OGG format Telegram expects for voice notes, sends it via the Telegram Bot API, and cleans up the temp files.

## What this skill is for (read first)

This skill exists to send **an assistant message that already exists in the conversation** as audio. It is **not** a way for the user to type out the text they want spoken. The text always comes from something the AI already produced in the chat history.

Two cases, and only these two:

- **Skill invoked with NO instruction** → speak the **last assistant message** (the message right before the user's request). This is the default. Take that message's text, run it through the pipeline below, and send it.
- **Skill invoked WITH an instruction** (e.g. "manda em áudio aquela explicação sobre o funil", "manda a penúltima resposta") → speak **the message the user pointed at**. Follow the instruction to pick which earlier assistant message to voice.

In both cases the source is an assistant output already in the history. The user is choosing *which* message becomes audio, not writing new content for it. Before generating, strip Markdown and convert symbols to spoken words (see "Make the text sound human"), but never rewrite the message's meaning.

The whole thing is three steps: **generate the MP3** (ElevenLabs) → **convert to OGG** (ffmpeg) → **send as voice** (Telegram `sendVoice`). A ready-to-run script bundles all of it.

## Quick start

First decide *which* message to voice (last assistant message by default, or the one the user pointed at). Then feed that message's text to the bundled script, which does generate → convert → send → cleanup in one shot:

```bash
scripts/send_voice.sh "Conteúdo da mensagem escolhida do histórico." casual
```

- Argument 1: the text of the chosen assistant message (wrap in quotes). Not new text the user typed.
- Argument 2 (optional): the emotion profile (`casual`, `analise`, `entusiasmado`, `serio`, `humor`). Defaults to `casual`.

To send to a different chat or use a different voice, override via environment variables (see "Configuration" below):

```bash
CHAT_ID=123456789 VOICE_ID=IKne3meq5aSn9XLyUdCD scripts/send_voice.sh "Olá" entusiasmado
```

## Configuration (credentials are baked in)

All credentials live inside `scripts/send_voice.sh` as defaults, so the script runs with zero setup. Each can be overridden with an environment variable if needed:

| Variable | What it is | Default |
|---|---|---|
| `ELEVENLABS_API_KEY` | ElevenLabs API key | `sk_fb3588053925457263d3ccf4ec61ad6f126773de75cb42d6` |
| `VOICE_ID` | ElevenLabs voice (Charlie, natural PT-BR male) | `IKne3meq5aSn9XLyUdCD` |
| `MODEL_ID` | ElevenLabs model | `eleven_multilingual_v2` |
| `BOT_TOKEN` | Telegram bot token | `8543452323:AAHeerjq0JgeVVPgZSrOHhTOF_DL6C541vI` |
| `CHAT_ID` | Telegram chat to send to | `468404811` |

Dependencies: `curl`, `ffmpeg` (with `libopus`). Both are standard. If `ffmpeg` is missing, install it first (`sudo apt install ffmpeg` on Debian/Ubuntu, `brew install ffmpeg` on macOS).

## Choosing the emotion profile

ElevenLabs reads emotion two ways: the numeric `voice_settings` AND the text itself. Pick the profile that matches the tone of what you're sending. `casual` covers ~70% of cases. The script maps each profile name to these settings:

- **casual** — normal conversation. `stability 0.35, similarity 0.75, style 0.45`
- **analise** — technical/structured explanation. `stability 0.55, similarity 0.75, style 0.20`
- **entusiasmado** — good news, excitement. `stability 0.20, similarity 0.75, style 0.65`
- **serio** — alert, problem, warning. `stability 0.65, similarity 0.80, style 0.10`
- **humor** — joke, lightness. `stability 0.25, similarity 0.70, style 0.60`

All profiles use `use_speaker_boost: true`.

**Rule of thumb:** lower `stability` = more expressive/varied; higher = more monotone/consistent. `style` amplifies the voice's natural delivery. Match the profile to the actual mood of the message, don't just default blindly.

## Make the text sound human

The model uses the text itself to calibrate delivery, so write for the ear, not the eye:

- **Pauses:** commas and ellipses create natural pauses. "Olha... isso é mais complicado do que parece."
- **Emphasis:** CAPS on a key word lands as stress. "NUNCA faça isso sem backup."
- **Emotional framing in the words:** instead of "os resultados foram bons", write "os resultados foram surpreendentemente bons, superaram o esperado."
- **Spoken connectives:** "Olha,", "Bom,", "Então," make it conversational.
- **Exclamations sparingly:** only for real enthusiasm.
- **Convert symbols to words before sending:** arrows (`→`), `=`, currency, URLs and bullets read badly. Spell them out ("trezentos mil dólares", "pré P M F", "r barra restaurateur"). The content stays intact, only the rendering changes.

## Doing it manually (if you don't want the script)

Step 1 — generate the MP3 with ElevenLabs:

```bash
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/IKne3meq5aSn9XLyUdCD" \
  -H "xi-api-key: sk_fb3588053925457263d3ccf4ec61ad6f126773de75cb42d6" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "TEXTO AQUI",
    "model_id": "eleven_multilingual_v2",
    "voice_settings": {
      "stability": 0.35,
      "similarity_boost": 0.75,
      "style": 0.45,
      "use_speaker_boost": true
    }
  }' \
  --output /tmp/audio_response.mp3
```

Step 2 — convert to OGG/Opus (Telegram voice format):

```bash
ffmpeg -i /tmp/audio_response.mp3 -c:a libopus /tmp/audio_response.ogg -y -loglevel quiet
```

Step 3 — send as a voice note via the Telegram Bot API:

```bash
curl -s -X POST "https://api.telegram.org/bot8543452323:AAHeerjq0JgeVVPgZSrOHhTOF_DL6C541vI/sendVoice" \
  -F "chat_id=468404811" \
  -F "voice=@/tmp/audio_response.ogg"
```

Step 4 — clean up the temp files (don't leave audio lying around):

```bash
rm -f /tmp/audio_response.mp3 /tmp/audio_response.ogg
```

## Notes and gotchas

- Use `sendVoice` (not `sendAudio`) so it shows up as a proper voice note with the waveform player.
- The OGG/Opus conversion matters. Telegram renders MP3 as a file attachment, not a voice note.
- Watch out for special characters (quotes, accents) in the JSON body. The bundled script writes the payload to a temp JSON file to avoid shell-escaping headaches, so prefer it for long or accented text.
- ElevenLabs free tier is ~10k characters/month. Long texts burn through it; check usage if generation suddenly fails.
- If ElevenLabs is down or out of quota, a free fallback is `edge-tts`: `edge-tts --voice "pt-BR-AntonioNeural" --text "Texto" --write-media /tmp/audio_response.ogg` (then send with step 3, skipping the ffmpeg step since edge-tts can write ogg directly).
