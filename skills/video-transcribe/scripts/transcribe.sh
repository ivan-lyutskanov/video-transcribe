#!/bin/bash
# Transcribe video/audio using local whisper.cpp
# Usage: transcribe.sh <input-file> [output-dir] [language]
# Environment variables:
#   WHISPER_MODEL - tiny, base, small (default), medium, large-v3
#   WHISPER_LANG - auto (default), bg, en, de, etc.

set -e

INPUT_FILE="$1"
OUTPUT_DIR="${2:-$HOME/transcripts}"
LANGUAGE="${3:-${WHISPER_LANG:-auto}}"

# Validate input
if [ -z "$INPUT_FILE" ]; then
    echo "Error: No input file specified"
    echo "Usage: $0 <input-file> [output-dir] [language]"
    echo "Env vars: WHISPER_MODEL=(tiny|base|small|medium), WHISPER_LANG=(auto|bg|en|...)"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File not found: $INPUT_FILE"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate output filename
BASENAME=$(basename "$INPUT_FILE" | sed 's/\.[^.]*$//')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/${BASENAME}-${TIMESTAMP}.txt"
AUDIO_FILE="/tmp/whisper-tmp-$$.wav"

echo "🔧 Processing: $INPUT_FILE"

# Extract audio if input is video
if ffprobe -v error -select_streams v -show_entries stream=codec_type -of csv=p=0 "$INPUT_FILE" 2>/dev/null | grep -q video; then
    echo "🎬 Extracting audio from video..."
    MSG="Extracting audio"
else
    echo "🎵 Input is audio, converting to wav..."
    MSG="Converting audio"
fi

if [ -n "$PROGRESS" ]; then
    # Get total duration in microseconds
    TOTAL_US=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT_FILE" 2>/dev/null | awk '{printf "%.0f", $1 * 1000000}')
    [ -z "$TOTAL_US" ] && TOTAL_US=0
    ffmpeg -i "$INPUT_FILE" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$AUDIO_FILE" -y \
      -loglevel error -progress pipe:1 2>/dev/null | while IFS='=' read -r key val; do
        case "$key" in
            out_time_us)
                pct=0
                [ "$TOTAL_US" -gt 0 ] && pct=$((val * 100 / TOTAL_US))
                [ "$pct" -gt 100 ] && pct=100
                printf "\r%s ... %d%%" "$MSG" "$pct"
                ;;
            progress)
                [ "$val" = "end" ] && printf "\r%s ... 100%%\n" "$MSG"
                ;;
        esac
    done
    # Check ffmpeg exit code (last in pipe)
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        echo "Error: ffmpeg failed"
        rm -f "$AUDIO_FILE"
        exit 1
    fi
else
    ffmpeg -i "$INPUT_FILE" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$AUDIO_FILE" -y -loglevel error
fi

# Check if whisper.cpp is available
WHISPER_BIN=$(which whisper-cli 2>/dev/null || echo "")

if [ -z "$WHISPER_BIN" ]; then
    # Try known locations on this VPS
    for path in /root/.openclaw/workspace/whisper/whisper.cpp-1.7.4/build/bin/whisper-cli /usr/local/bin/whisper-cli /usr/bin/whisper-cli; do
        if [ -x "$path" ]; then
            WHISPER_BIN="$path"
            break
        fi
    done
fi

if [ -z "$WHISPER_BIN" ]; then
    echo "Error: whisper.cpp not found. Please install whisper.cpp and ensure it's in PATH."
    rm -f "$AUDIO_FILE"
    exit 1
fi

echo "🎯 Transcribing with whisper.cpp..."
echo "   Binary: $WHISPER_BIN"

# Model selection
# small = default, good balance for Bulgarian (better than base, not too slow like medium)
MODEL_SIZE="${WHISPER_MODEL:-small}"

# Warn about large models on 8GB systems
if [ "$MODEL_SIZE" = "large" ] || [ "$MODEL_SIZE" = "large-v3" ] || [ "$MODEL_SIZE" = "large-v2" ] || [ "$MODEL_SIZE" = "large-v1" ]; then
    echo "⚠️  Warning: $MODEL_SIZE model may use 10GB+ RAM. Press Ctrl+C to cancel, or wait 5s to continue..."
    sleep 5
fi

MODEL_NAME="ggml-${MODEL_SIZE}.bin"
MODEL_DIR="${HOME}/.local/share/whisper.cpp"
MODEL_PATH="$MODEL_DIR/$MODEL_NAME"

echo "🧠 Model: $MODEL_SIZE | Language: $LANGUAGE"

# Download model if not exists
if [ ! -f "$MODEL_PATH" ]; then
    echo "📥 Downloading model: $MODEL_NAME (~150MB-3GB depending on size)"
    mkdir -p "$MODEL_DIR"
    curl -L --progress-bar "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$MODEL_NAME" -o "$MODEL_PATH" || {
        echo "Error: Failed to download model. Check model name: $MODEL_SIZE"
        rm -f "$AUDIO_FILE"
        exit 1
    }
fi

# Build whisper args
WHISPER_ARGS="-m $MODEL_PATH -f $AUDIO_FILE"

[ -n "$PROGRESS" ] && WHISPER_ARGS="$WHISPER_ARGS -pp"

# Add language if explicitly specified (not auto)
if [ "$LANGUAGE" != "auto" ]; then
    WHISPER_ARGS="$WHISPER_ARGS -l $LANGUAGE"
fi

# Transcribe (progress goes to stderr when -pp is used)
if [ -n "$PROGRESS" ]; then
    $WHISPER_BIN $WHISPER_ARGS > "/tmp/whisper-out-$$.txt"
else
    $WHISPER_BIN $WHISPER_ARGS > "/tmp/whisper-out-$$.txt" 2>/dev/null
fi

# Process output to add timestamps
if [ -f "/tmp/whisper-out-$$.txt" ]; then
    # Add header and format
    echo "# Transcript: $BASENAME" > "$OUTPUT_FILE"
    echo "# Date: $(date -Iseconds)" >> "$OUTPUT_FILE"
    echo "# Source: $INPUT_FILE" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    cat "/tmp/whisper-out-$$.txt" >> "$OUTPUT_FILE"
else
    echo "Error: Transcription failed"
    rm -f "$AUDIO_FILE" "/tmp/whisper-out-$$.txt"
    exit 1
fi

# Cleanup
rm -f "$AUDIO_FILE" "/tmp/whisper-out-$$.txt"

echo "✅ Transcript saved: $OUTPUT_FILE"
echo ""
head -20 "$OUTPUT_FILE"
