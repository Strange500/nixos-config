#!/usr/bin/env bash
# Universal voice dictation toggle agent (issue #48).
#
# Pure user-space. Invoked by the Niri keybind (Mod+D):
#   - first press  -> starts recording in the background
#   - second press -> stops recording, transcribes with whisper-cpp, and types
#                     the text into the currently-focused window via `ydotool`.
#
# State lives in a lock + pidfile under $XDG_RUNTIME_DIR (or ~/.cache) so two
# consecutive keypresses (two separate processes) coordinate cleanly.

set -u

# --- config ---------------------------------------------------------------
# Whisper model name (must match `whisper-cpp-download-ggml-model` list).
MODEL="${DICTATION_MODEL:-small}"
MODEL_DIR="${DICTATION_MODEL_DIR:-$HOME/.local/share/dictation/models}"
MODEL_BIN="$MODEL_DIR/ggml-$MODEL.bin"

# Where the ydotool daemon socket lives. The system module sets
# YDOTOOL_SOCKET globally; fall back to the NixOS module default.
YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-/run/ydotoold/socket}"

STATE_DIR="${XDG_RUNTIME_DIR:-$HOME/.cache}/dictation"
LOCK="$STATE_DIR/recording.lock"
PIDFILE="$STATE_DIR/recording.pid"
WAV="$STATE_DIR/recording.wav"
TXT="$STATE_DIR/recording.txt"

mkdir -p "$STATE_DIR" "$MODEL_DIR"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a dictation "$1" "$2"; }

is_recording() {
  [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null
}

start_recording() {
  # Clear any stale transcript from a previous session.
  rm -f "$TXT"
  notify "🎙️ Dictée" "Enregistrement… (re-appuyez sur Mod+D pour arrêter)"
  # Mono 16 kHz 16-bit — whisper's expected input. The container is inferred
  # from the .wav extension of $WAV (pw-record has no --container flag).
  pw-record --format s16 --rate 16000 --channels 1 "$WAV" &
  local pid=$!
  echo "$pid" >"$PIDFILE"
  echo "$WAV" >"$LOCK"
}

stop_and_inject() {
  local pid
  pid="$(cat "$PIDFILE" 2>/dev/null)"
  rm -f "$PIDFILE" "$LOCK"

  # Ask the recorder to stop gracefully (SIGINT finalizes the WAV header).
  [ -n "${pid:-}" ] && kill -INT "$pid" 2>/dev/null

  # The recorder is a child of the PREVIOUS keypress process, so `wait` can't
  # see it. Poll until the WAV stops growing so whisper reads a complete file.
  local size last=-1
  for _ in $(seq 1 40); do
    size="$(stat -c %s "$WAV" 2>/dev/null || echo 0)"
    [ "$size" -gt 0 ] && [ "$size" = "$last" ] && break
    last="$size"
    sleep 0.05
  done

  if [ ! -s "$WAV" ]; then
    notify "⚠️ Dictée" "Aucun audio enregistré."
    return 1
  fi

  ensure_model
  notify "⏳ Transcription…" "Whisper traite votre dictée."

  # Deterministic text output: write plain text next to the recording, then
  # read it back. -l fr forces French, -nt drops timestamps, -np silences
  # progress spam on stderr.
  rm -f "$TXT"
  whisper-cli \
    -m "$MODEL_BIN" \
    -l fr \
    -nt \
    -np \
    -otxt \
    -of "$STATE_DIR/recording" \
    -f "$WAV" >/dev/null 2>&1

  local text
  text="$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$TXT" 2>/dev/null | grep -v '^$' | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"

  if [ -z "$text" ]; then
    notify "⚠️ Dictée" "Aucune parole reconnue."
    return 1
  fi

  # Type the recognized text into the focused window, preserving French
  # accents (UTF-8). ydotool injects key events so it respects the active
  # keyboard layout.
  if ! echo -n "$text" | ydotool type --file - 2>/dev/null; then
    notify "❌ Dictée" "Échec de l'injection (ydotoold démarré ?)."
    return 1
  fi

  notify "✅ Dictée" "$text"
}

ensure_model() {
  if [ -s "$MODEL_BIN" ]; then
    return 0
  fi
  notify "⬇️ Dictée" "Téléchargement du modèle Whisper ($MODEL)…"
  # The nixpkgs-wrapped download script takes ONLY the model name and saves
  # into the current directory.
  (cd "$MODEL_DIR" && whisper-cpp-download-ggml-model "$MODEL")
}

main() {
  if is_recording; then
    stop_and_inject
  else
    start_recording
  fi
}

main "$@"
