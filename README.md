# Video Transcribe

Local video/audio transcription using [whisper.cpp](https://github.com/ggerganov/whisper.cpp) — no API keys, no cloud, fully private.

Designed for [opencode](https://opencode.ai) as a reusable skill, but works with any AI coding agent or directly from the command line.

Transcribes speech from video files, audio files, Telegram voice messages, or URLs into timestamped text files.

## Features

- **100% local** — runs on your machine, nothing leaves your computer
- **Multi-language** — Bulgarian, English, and 90+ languages supported
- **Batch processing** — transcribe entire directories at once
- **Progress bars** — see conversion and transcription progress
- **Auto model download** — models download on first use and cache locally
- **Flexible input** — local files, URLs, Telegram audio messages

## Usage Options

### Run manually (any terminal)

```bash
# From the repo root
skills/video-transcribe/scripts/transcribe.sh video.mp4

# Or place the script anywhere and use it standalone
/path/to/transcribe.sh video.mp4
```

### Use with opencode (recommended)

[opencode](https://opencode.ai) is an AI coding assistant that supports reusable skills. Install this skill so opencode can transcribe videos for you automatically.

```bash
# Clone the repo
git clone https://github.com/ivan-lyutskanov/video-transcribe.git ~/Projects/video-transcribe

# Symlink the skill into opencode's skills directory
mkdir -p ~/.config/opencode/skills
ln -s ~/Projects/video-transcribe/skills/video-transcribe ~/.config/opencode/skills/video-transcribe
```

Once installed, opencode will automatically load the skill and you can ask it to transcribe videos, batch process directories, or extract audio from any media file.

### Use with other AI agents

The scripts are plain bash — any AI coding agent (Claude Code, Cursor, etc.) can invoke them directly via terminal commands. Point your agent to the script paths and it can transcribe, batch process, or integrate transcription into larger workflows.

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

### Windows (via WSL)

```powershell
# Install WSL2 with Ubuntu, then follow the Linux instructions inside WSL
wsl --install -d Ubuntu
# After reboot, open Ubuntu terminal and run the Linux (Ubuntu/Debian) steps above
```

All scripts run inside the WSL terminal. Place your media files in a Windows folder accessible from WSL at `/mnt/c/Users/YourName/...`.

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
# Defaults: language=en, model=medium
./transcribe-all.sh

# Custom language and model
./transcribe-all.sh en small
```

### Transcribe from a URL

```bash
curl -L -o /tmp/video.mp4 "https://example.com/video.mp4" && \
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
# English with medium model (defaults)
./transcribe-all.sh

# Bulgarian with medium model
./transcribe-all.sh bg

# Small model with auto language detection
./transcribe-all.sh auto small
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

1. Download video videos
2. Run transcription
3. Read and summarize the transcript
4. Store notes alongside the transcript

```bash
# Step 1: Download
curl -L -o video01.mp4 "https://example.com/video01.mp4"

# Step 2: Transcribe
skills/video-transcribe/scripts/transcribe.sh video01.mp4 ./transcripts bg

# Step 3: Read the output
cat ./transcripts/video01-*.txt
```

### Telegram voice messages

```bash
# Download from Telegram, then transcribe (defaults to Bulgarian)
skills/video-transcribe/scripts/transcribe.sh voice.ogg "" bg
```

## Output Format

Transcripts are saved as plain text files with metadata headers:

```
# Transcript: video01
# Date: 2025-01-01T12:00:00+00:00
# Source: /path/to/video01.mp4

[00:00:00 --> 00:00:05]  Hello and welcome to this lecture.
[00:00:05 --> 00:00:10]  Today we will talk about large language models and how they work.
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
