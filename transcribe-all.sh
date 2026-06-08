#!/bin/bash
# Transcribe all video/audio files in current directory with progress
# Usage: ./transcribe-all.sh [language] [model]
#   language: bg (default), en, auto, etc.
#   model: medium (default), small, tiny, base, large-v3

LANG="${1:-bg}"
MODEL="${2:-medium}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Collect files
files=()
for ext in mp4 avi mkv mov mp3 wav m4a ogg; do
  for f in "$SCRIPT_DIR"/*."$ext"; do
    [ -f "$f" ] && files+=("$f")
  done
done

total="${#files[@]}"
[ "$total" -eq 0 ] && echo "No media files found." && exit 0

echo "========================================"
echo " Files to transcribe: $total"
echo " Language: $LANG  |  Model: $MODEL"
echo "========================================"
echo ""

count=0
for f in "${files[@]}"; do
  count=$((count + 1))
  name="$(basename "$f")"
  echo "━━━ [$count/$total] $name ━━━"
  echo ""
  PROGRESS=1 WHISPER_MODEL="$MODEL" WHISPER_LANG="$LANG" \
    "$SCRIPT_DIR/skills/video-transcribe/scripts/transcribe.sh" "$f" "$SCRIPT_DIR" "$LANG"
  echo ""
done

echo "============================================"
echo " Done! $total transcripts saved in: $SCRIPT_DIR"
echo "============================================"
