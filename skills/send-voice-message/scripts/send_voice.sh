#!/usr/bin/env bash
#
# send_voice.sh — Generate a voice message with ElevenLabs and send it to Telegram.
#
# Usage:
#   ./send_voice.sh "Text to speak" [profile]
#
# profile (optional): casual | analise | entusiasmado | serio | humor   (default: casual)
#
# Override any credential/config via environment variable, e.g.:
#   CHAT_ID=123456789 ./send_voice.sh "Olá" entusiasmado
#
set -euo pipefail

# ---- Configuration (credentials baked in, overridable via env) ----
ELEVENLABS_API_KEY="${ELEVENLABS_API_KEY:-sk_fb3588053925457263d3ccf4ec61ad6f126773de75cb42d6}"
VOICE_ID="${VOICE_ID:-IKne3meq5aSn9XLyUdCD}"          # Charlie — natural PT-BR male
MODEL_ID="${MODEL_ID:-eleven_multilingual_v2}"
BOT_TOKEN="${BOT_TOKEN:-8543452323:AAHeerjq0JgeVVPgZSrOHhTOF_DL6C541vI}"
CHAT_ID="${CHAT_ID:-468404811}"

# ---- Arguments ----
TEXT="${1:-}"
PROFILE="${2:-casual}"

if [[ -z "$TEXT" ]]; then
  echo "Error: no text provided." >&2
  echo "Usage: $0 \"Text to speak\" [casual|analise|entusiasmado|serio|humor]" >&2
  exit 1
fi

# ---- Emotion profile -> voice_settings ----
case "$PROFILE" in
  casual)        STABILITY=0.35; SIMILARITY=0.75; STYLE=0.45 ;;
  analise)       STABILITY=0.55; SIMILARITY=0.75; STYLE=0.20 ;;
  entusiasmado)  STABILITY=0.20; SIMILARITY=0.75; STYLE=0.65 ;;
  serio)         STABILITY=0.65; SIMILARITY=0.80; STYLE=0.10 ;;
  humor)         STABILITY=0.25; SIMILARITY=0.70; STYLE=0.60 ;;
  *)
    echo "Unknown profile '$PROFILE'. Using 'casual'." >&2
    STABILITY=0.35; SIMILARITY=0.75; STYLE=0.45 ;;
esac

# ---- Dependency checks ----
command -v curl >/dev/null 2>&1   || { echo "Error: curl not found." >&2; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || { echo "Error: ffmpeg not found (needed for OGG/Opus conversion)." >&2; exit 1; }

# ---- Temp files (cleaned up on exit) ----
MP3="$(mktemp /tmp/voice_XXXXXX.mp3)"
OGG="$(mktemp /tmp/voice_XXXXXX.ogg)"
PAYLOAD="$(mktemp /tmp/voice_XXXXXX.json)"
cleanup() { rm -f "$MP3" "$OGG" "$PAYLOAD"; }
trap cleanup EXIT

# ---- Build JSON payload safely (handles quotes/accents in TEXT) ----
# Uses a heredoc with a JSON-escaped string produced by a tiny inline encoder.
ESCAPED_TEXT=$(printf '%s' "$TEXT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || true)
if [[ -z "$ESCAPED_TEXT" ]]; then
  # Fallback escaping without python: escape backslash and double-quote, drop newlines.
  ESCAPED_TEXT="\"$(printf '%s' "$TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')\""
fi

cat > "$PAYLOAD" <<EOF
{
  "text": ${ESCAPED_TEXT},
  "model_id": "${MODEL_ID}",
  "voice_settings": {
    "stability": ${STABILITY},
    "similarity_boost": ${SIMILARITY},
    "style": ${STYLE},
    "use_speaker_boost": true
  }
}
EOF

# ---- Step 1: ElevenLabs TTS -> MP3 ----
echo "Generating audio (profile: $PROFILE)..." >&2
HTTP_CODE=$(curl -s -w "%{http_code}" -X POST \
  "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
  -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
  -H "Content-Type: application/json" \
  --data-binary "@${PAYLOAD}" \
  --output "$MP3")

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "Error: ElevenLabs returned HTTP $HTTP_CODE." >&2
  echo "Response body:" >&2
  cat "$MP3" >&2 || true
  exit 1
fi

# ---- Step 2: Convert to OGG/Opus (Telegram voice format) ----
echo "Converting to OGG/Opus..." >&2
ffmpeg -i "$MP3" -c:a libopus "$OGG" -y -loglevel quiet

# ---- Step 3: Send as voice note via Telegram ----
echo "Sending to Telegram chat $CHAT_ID..." >&2
RESPONSE=$(curl -s -X POST \
  "https://api.telegram.org/bot${BOT_TOKEN}/sendVoice" \
  -F "chat_id=${CHAT_ID}" \
  -F "voice=@${OGG}")

if echo "$RESPONSE" | grep -q '"ok":true'; then
  echo "Sent successfully." >&2
else
  echo "Error: Telegram send failed." >&2
  echo "$RESPONSE" >&2
  exit 1
fi

# Cleanup handled by trap.
