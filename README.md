# Scout (iOS, SwiftUI + ShazamKit + DSP)

**What it does**
- Listens via the microphone, identifies the song using **ShazamKit**.
- Estimates **chords** and **piano notes** in real-time using lightweight on-device DSP (YIN pitch tracker + chromagram + chord template matching).
- Fetches **lyrics** via **MusicKit** when the user is an Apple Music subscriber and authorization is granted (falls back gracefully).
- Shows the **song title/artist**, current **chord**, detected **notes**, **lyrics**, and a **piano keyboard animation**.

> This is a complete, ready-to-open SwiftUI project skeleton. Open in Xcode 15+ (iOS 17+ target recommended). Enable capabilities in the steps below.

---

## Quick Start

1. **Open in Xcode**  
   - File → Open → select the `Scout` folder (this folder).  
   - Xcode will detect it as a Swift app project; if prompted, create a new iOS App project and add all files under `Scout/Sources`.

2. **Set bundle identifier** (e.g., `com.yourname.Scout`) and **Team** in Signing & Capabilities.

3. **Capabilities / Info**  
   - *Microphone*: Add **`NSMicrophoneUsageDescription`** to Info with a clear string (already added in `Info.plist`).  
   - *Music & Shazam*: Add **Apple Music** and **ShazamKit** capabilities in Signing & Capabilities. Also ensure **`NSAppleMusicUsageDescription`** is present (already added).

4. **MusicKit Developer Token (optional but recommended for lyrics)**  
   - Create a developer token (Apple Developer account).  
   - Set it at runtime in `LyricsService.swift` (see `// TODO: Set your developer token`).  
   - Without a token, song matching still works; lyrics may be unavailable.

5. **Run on a real device** for mic + audio; Simulator has limited mic behavior.

---

## Architecture

- `Sources/Models` — lightweight data models (notes/chords/song info).
- `Sources/Services` — audio capture (AVAudioEngine), Shazam matching (ShazamKit), DSP (pitch + chroma + chord), lyrics (MusicKit).
- `Sources/Views` — SwiftUI screens and piano keyboard animation.
- `Sources/Utils` — helpers, smoothing, circular buffers, frequency maps.

DSP is deliberately simple and efficient (44.1kHz mono). It’s not studio-grade, but works for common pop/rock harmonies and sustained notes.

---

## Known Limitations / Notes

- **Lyrics**: Availability depends on Apple Music catalog and user’s subscription. Dev token + user authorization required. Falls back if not available.
- **Chords**: Estimation uses a classical chroma/template approach; rapid modulations or complex jazz voicings will be approximated.
- **Latency**: Kept low via 2048-sample hop (~46ms at 44.1kHz). Tune `DSPConfig` to trade accuracy vs. latency.
- **Legal**: Ensure your usage complies with Apple Music & ShazamKit terms for production deployment.

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
  Sources/
    Models/
      DetectedNote.swift
      DetectedChord.swift
      SongInfo.swift
    Services/
      AudioManager.swift
      ShazamMatcher.swift
      ChordDetector.swift
      LyricsService.swift
    Utils/
      DSP.swift
      MusicHelpers.swift
      Smoother.swift
    Views/
      ContentView.swift
      PianoKeyboardView.swift
      SongDetailView.swift
```

---

## Attribution
- Pitch detection: YIN variant.
- Chroma: vDSP FFT + pitch-class aggregation.
- Chord templates: 12 major + 12 minor triad profiles.
- ShazamKit for identification.
- MusicKit for catalog metadata & lyrics.
