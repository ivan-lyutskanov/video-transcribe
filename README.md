# Video Transcribe

Local video/audio transcription using [whisper.cpp](https://github.com/ggerganov/whisper.cpp) — no API keys, no cloud, fully private.

Transcribes speech from video files, audio files, Telegram voice messages, or URLs into timestamped text files.

## Features

- **100% local** — runs on your machine, nothing leaves your computer
- **Multi-language** — Bulgarian, English, and 90+ languages supported
- **Batch processing** — transcribe entire directories at once
- **Progress bars** — see conversion and transcription progress
- **Auto model download** — models download on first use and cache locally
- **Flexible input** — local files, URLs, Telegram audio messages

## Dependencies

### macOS

```bash
brew install ffmpeg whisper-cpp
```

### Linux (Ubuntu/Debian)

```bash
sudo apt update && sudo apt install -y ffmpeg build-essential
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp
make -j
# Optional: add to PATH
sudo ln -s "$(pwd)/build/bin/whisper-cli" /usr/local/bin/whisper-cli
```

### Linux (Arch)

```bash
sudo pacman -S ffmpeg whisper-cpp
```

### Verify installation

```bash
ffmpeg -version
whisper-cli --help 2>/dev/null || echo "whisper-cli needs to be in PATH"
```

## Quick Start

### Single file transcription

```bash
skills/video-transcribe/scripts/transcribe.sh path/to/video.mp4
```

Output: `~/transcripts/video-20250101-120000.txt`

### Specify output directory and language

```bash
skills/video-transcribe/scripts/transcribe.sh path/to/audio.ogg ./output bg
```

### Transcribe all files in current directory

```bash
# Defaults: language=bg, model=medium
./transcribe-all.sh

# Custom language and model
./transcribe-all.sh en small
```

### Transcribe from a URL

```bash
curl -L -o /tmp/video.mp4 "https://example.com/lecture.mp4" && \
  skills/video-transcribe/scripts/transcribe.sh /tmp/video.mp4
```

## Language Support

whisper.cpp auto-detects language by default. For better accuracy with non-English content, specify the language explicitly.

| Code | Language |
|------|----------|
| `auto` | Auto-detect (default) |
| `bg` | Bulgarian |
| `en` | English |
| `de` | German |
| `fr` | French |
| `es` | Spanish |
| `ru` | Russian |

Common codes: `bg`, `en`, `de`, `fr`, `es`, `ru`, `it`, `pt`, `nl`, `pl`, `tr`.

## Model Selection

Set via the `WHISPER_MODEL` environment variable (default: `small`).

```bash
WHISPER_MODEL=medium skills/video-transcribe/scripts/transcribe.sh video.mp4
```

| Model | English | Bulgarian | Speed | RAM |
|-------|---------|-----------|-------|-----|
| `tiny` | OK | Poor | Fastest | ~1 GB |
| `base` | Good | Fair | Fast | ~1 GB |
| `small` | Very Good | Good | Medium | ~2 GB |
| `medium` | Excellent | Very Good | Slow | ~5 GB |
| `large-v3` | Best | Best | Very Slow | ~10+ GB |

**Recommendations:**
- **Bulgarian:** `small` minimum. `base` works but misses grammatical morphology.
- **English:** `base` or `small` is sufficient for most use cases.
- **8 GB RAM systems:** Use at most `medium`. `large-v3` requires >10 GB RAM.

Models auto-download on first use and cache in `~/.local/share/whisper.cpp/`.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WHISPER_MODEL` | `small` | Model size: `tiny`, `base`, `small`, `medium`, `large-v3` |
| `WHISPER_LANG` | `auto` | Language: `auto`, `bg`, `en`, `de`, etc. |
| `PROGRESS` | (unset) | Set to `1` to enable progress bars |

## Batch Processing

### Using `transcribe-all.sh`

Place the script in a directory with media files and run:

```bash
# Bulgarian with medium model (defaults)
./transcribe-all.sh

# English with small model
./transcribe-all.sh en small

# Auto-detect with base model
./transcribe-all.sh auto base
```

Supported formats: `mp4`, `avi`, `mkv`, `mov`, `mp3`, `wav`, `m4a`, `ogg`.

### Using a shell loop

```bash
for video in ./course/*.mp4; do
  WHISPER_MODEL=medium skills/video-transcribe/scripts/transcribe.sh "$video" ./transcripts bg
done
```

## Integration Examples

### Course workflow

1. Download lecture videos
2. Run transcription
3. Read and summarize the transcript
4. Store notes alongside the transcript

```bash
# Step 1: Download
curl -L -o lecture01.mp4 "https://example.com/lecture01.mp4"

# Step 2: Transcribe
skills/video-transcribe/scripts/transcribe.sh lecture01.mp4 ./transcripts bg

# Step 3: Read the output
cat ./transcripts/lecture01-*.txt
```

### Telegram voice messages

```bash
# Download from Telegram, then transcribe (defaults to Bulgarian)
skills/video-transcribe/scripts/transcribe.sh voice.ogg "" bg
```

## Output Format

Transcripts are saved as plain text files with metadata headers:

```
# Transcript: lecture01
# Date: 2025-01-01T12:00:00+00:00
# Source: /path/to/lecture01.mp4

[00:00:00 --> 00:00:05]  Добър ден и добре дошли на лекцията.
[00:00:05 --> 00:00:10]  Днес ще говорим за основите на програмирането.
...
```

## Directory Structure

```
video-transcribe/
├── README.md              # This file
├── transcribe-all.sh      # Batch transcription script
└── skills/
    └── video-transcribe/
        ├── SKILL.md        # opencode skill definition
        └── scripts/
            └── transcribe.sh  # Main transcription script
```
