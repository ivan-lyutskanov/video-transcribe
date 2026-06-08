---
name: video-transcribe
description: Extract transcripts from video and audio files using local whisper.cpp. Use when transcribing course content, meetings, podcasts, or any video/audio to text. Supports multiple input sources including local files, URLs, and Telegram audio messages.
---

# Video/Audio Transcription

Extract transcripts from video/audio using local whisper.cpp — no API keys needed.

## Prerequisites

- whisper.cpp (`brew install whisper-cpp`)
- ffmpeg (`brew install ffmpeg`)

## Quick Start

### Transcribe a local video file:
```bash
skills/video-transcribe/scripts/transcribe.sh /path/to/video.mp4
```

### Transcribe a Telegram voice message (defaults to Bulgarian):
```bash
skills/video-transcribe/scripts/transcribe.sh /path/to/audio.ogg "" bg
```

### Transcribe from URL (downloads first):
```bash
curl -L -o /tmp/video.mp4 "https://example.com/video.mp4" && \
skills/video-transcribe/scripts/transcribe.sh /tmp/video.mp4
```

### Explicit language selection:
```bash
# Force Bulgarian (default for Telegram voice messages)
skills/video-transcribe/scripts/transcribe.sh /path/to/audio.ogg "" bg

# Force English
skills/video-transcribe/scripts/transcribe.sh /path/to/audio.ogg "" en

# Auto-detect (for mixed/unknown)
skills/video-transcribe/scripts/transcribe.sh /path/to/audio.ogg "" auto
```

## Output

- Saves transcript to workspace: `transcripts/<filename>-<timestamp>.txt`
- Includes timestamps (HH:MM:SS format)
- Returns the file path for further processing

## Workflow for Course Content

1. Extract audio: ffmpeg extracts audio from video
2. Transcribe: whisper.cpp converts speech to text
3. Save: Output to workspace transcripts/ folder
4. Process: Use transcript for note-taking, summarization, or storage

## Model Options

Default: `small` (good balance for Bulgarian and other languages)

| Model | English | Bulgarian | Speed | RAM Use |
|-------|---------|-----------|-------|---------|
| `tiny` | OK | Poor | Fastest | ~1GB |
| `base` | Good | Fair | Fast | ~1GB |
| `small` | Very Good | Good | Medium | ~2GB |
| `medium` | Excellent | Very Good | Slow | ~5GB |

**For Bulgarian:** `small` minimum recommended. `base` works but misses morphology.

**Change model:**
```bash
WHISPER_MODEL=medium skills/video-transcribe/scripts/transcribe.sh video.mp4
```

**Note:** `large-v3` requires >8GB RAM — use `medium` max on 8GB systems.

Models auto-download on first use and cache in `~/.local/share/whisper.cpp/`.

## Language Support

whisper.cpp auto-detects language by default. For Bulgarian or mixed content, explicit language helps:

```bash
# Force Bulgarian
skills/video-transcribe/scripts/transcribe.sh video.mp4 "" bg

# Force English
skills/video-transcribe/scripts/transcribe.sh video.mp4 "" en
```

Common codes: `bg`, `en`, `de`, `fr`, `es`, `ru`, `it`, `pt`, `nl`, `pl`, `tr`, etc.

For non-English content, accuracy improves significantly with larger models.

## Integration Examples

### Batch process a course:
```bash
for video in /path/to/course/*.mp4; do
  skills/video-transcribe/scripts/transcribe.sh "$video"
done
```

### Extract then summarize:
1. Run transcription
2. Read output file
3. Create summary notes in `memory/course-name/`
