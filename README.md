# Scout (iOS, SwiftUI + ShazamKit + DSP)

**What it does**
- Listens via the microphone.
- Estimates **chords** and **piano notes** in real-time using lightweight on-device DSP (YIN pitch tracker + chromagram + chord template matching).
- Displays the current **chord**, detected **note**, a **piano keyboard animation**, and a **live audio visualizer**.

> This is a complete, ready-to-open SwiftUI project skeleton. Open in Xcode 15+ (iOS 17+ target recommended). Enable capabilities in the steps below.

---

## Quick Start

1. **Open in Xcode**  
   - File → Open → select the `Scout` folder (this folder).  
   - Xcode will detect it as a Swift app project; if prompted, create a new iOS App project and add all files under `Scout/Sources`.

2. **Set bundle identifier** (e.g., `com.yourname.Scout`) and **Team** in Signing & Capabilities.

3. **Capabilities / Info**  
   - *Microphone*: Add **`NSMicrophoneUsageDescription`** to Info with a clear string (already added in `Info.plist`).  

4. **Run on a real device** for mic + audio; Simulator has limited mic behavior.

---

## Architecture

- `Models` — Lightweight data models (notes/chords).
- `Services` — Handles audio capture (`AudioManager`) and Digital Signal Processing for chord/note detection (`ChordDetector`).
- `Views` — All SwiftUI screens, including the main content view, piano keyboard, and audio visualizer.
- `Utils` — Helper files for DSP configuration and smoothing audio data.

The DSP is designed to be simple and efficient, making it suitable for real-time analysis on a mobile device.

---

## Known Limitations

- **Chords**: The detection uses a classical chroma/template approach. It works well for common pop and rock harmonies but may approximate more complex jazz voicings or rapid modulations.
- **Latency**: Tuned for low latency to feel responsive. You can adjust the settings in `DSPConfig.swift` to trade accuracy for lower latency if needed.

---

## iOS Deployment Target
iOS 17.0+ (can lower with minor code edits).

---

## File Tree
```
Scout/
  Assets.xcassets/
  Info.plist
  ScoutApp.swift
    Models/
      DetectedNote.swift
      DetectedChord.swift
    Services/
      AudioManager.swift
      ChordDetector.swift
    Utils/
      DSP.swift
      Smoother.swift
    Views/
      ContentView.swift
      PianoKeyboardView.swift
      SplashScreenView.swift
```

---

## Attribution
- Pitch detection: A simplified YIN-like algorithm.
- Chroma generation: Apple's Accelerate framework (vDSP) for FFT, followed by pitch-class aggregation.
- Chord templates: 12 major + 12 minor triad profiles.
