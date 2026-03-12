# Sasayaku (囁く)

macOS menu bar app for push-to-talk speech transcription. Hold a key, speak, release — transcribed text is pasted wherever your cursor is. Fully local transcription powered by Whisper, optimized for Spanish.

## How it works

```
Hold ⌥ Option → Record audio → Release → Whisper transcribes → Text pasted at cursor
```

## Requirements

- macOS 14+
- Apple Silicon (M1/M2/M3/M4)
- Xcode Command Line Tools (`xcode-select --install`)

## Install

```bash
make install    # builds release + installs to /Applications
```

Or build and run without installing:

```bash
make run        # builds release .app bundle and opens it
```

Other commands:

```bash
make build      # just build the .app bundle
make uninstall  # remove from /Applications
make clean      # clean build artifacts
```

## Getting started

### 1. Launch the app

After `make install`, open Sasayaku from Applications or Spotlight. A mic icon (🎤) will appear in your menu bar.

### 2. Grant permissions

- **Microphone**: the system will prompt you automatically on first launch
- **Accessibility**: go to System Settings → Privacy & Security → Accessibility → enable Sasayaku. This is required for the global hotkey and text pasting to work.

### 3. Download a model

Click the mic icon in the menu bar. You'll see a yellow "Setup needed" status with a **Download Model** button. Click it and wait for the download to complete.

The default model is **Medium** (~1.5 GB) — it provides the best transcription quality for Spanish. If you have less than 16 GB of RAM, switch to **Small** (~466 MB) in Settings before downloading.

### 4. Start using it

Once the status turns green ("Ready"), hold **⌥ Option**, speak, and release. The transcribed text will be pasted wherever your cursor is — works in any app.

## Usage

| Action | What happens |
|--------|-------------|
| **Hold ⌥ Option** | Starts recording (icon turns green) |
| **Release ⌥ Option** | Stops recording, transcribes, pastes text (icon turns orange, then back to normal) |
| **Click menu bar icon** | Opens the popup with status, last transcription, and settings |

### Menu bar icon colors

- ⚪ **Normal** — idle, ready to record
- 🟢 **Green** — recording in progress
- 🟠 **Orange** — transcribing audio
- 🔴 **Red** — error (check the popup for details)

## Models

| Model | Download | RAM usage | Quality | Speed |
|-------|----------|-----------|---------|-------|
| Tiny | ~75 MB | ~200 MB | Basic | Fastest |
| Base | ~142 MB | ~300 MB | Good | Fast |
| Small | ~466 MB | ~850 MB | Great | Fast |
| **Medium** | **~1.5 GB** | **~3 GB** | **Best** | **Default** |

Models are downloaded from HuggingFace on first use and stored in:
```
~/Library/Application Support/Sasayaku/Models/
```

You can change the model in Settings at any time. The new model will be downloaded if not already present.

## Permissions

| Permission | Why it's needed | How to grant |
|------------|----------------|--------------|
| Microphone | Capture audio while recording | Automatic prompt on first launch |
| Accessibility | Global hotkey + paste text via Cmd+V | System Settings → Privacy & Security → Accessibility |

## Architecture

- **UI**: SwiftUI `MenuBarExtra` — menu bar only, no dock icon (`LSUIElement`)
- **Transcription**: [SwiftWhisper](https://github.com/exPHAT/SwiftWhisper) (whisper.cpp via SPM)
- **Audio**: AVAudioEngine → 16kHz mono Float32 with automatic resampling
- **Hotkey**: `NSEvent` global/local monitor on `flagsChanged`
- **Text insertion**: Pasteboard + simulated Cmd+V via CGEvent (original clipboard is restored)

## Project structure

```
Sources/Sasayaku/
├── App/           SasayakuApp, AppDelegate, AppCoordinator
├── Views/         MenuBarView, SettingsView, StatusIndicator
├── Services/      AudioCapture, Transcription, Hotkey, TextInsertion
├── Models/        AppState, WhisperModel
└── Utilities/     ModelDownloader, Permissions
```
