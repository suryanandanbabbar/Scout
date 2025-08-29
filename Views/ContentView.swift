import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audio = AudioManager.shared
    @StateObject private var chorder = ChordDetector()
    
    @State private var isListening = false
    @State private var pulse = false // For button animation
    
    private let analysisQueue = DispatchQueue(label: "com.scout.analysis")
    
    // Define a dark, vibrant color scheme
    private let backgroundColor = Color(red: 0.05, green: 0.0, blue: 0.1)
    private let accentColor = Color.purple
    
    var body: some View {
        ZStack {
            // MARK: - Background Layer
            backgroundColor.ignoresSafeArea()
            
            // MARK: - Main Content Layer
            if isListening {
                listeningView
                    .transition(.opacity.animation(.easeIn))
            } else {
                idleView
                    .transition(.opacity.animation(.easeIn))
            }
        }
        .onAppear(perform: requestMicPermission)
    }
    
    // MARK: - Idle View
    var idleView: some View {
        VStack {
            Spacer()
            Text("Scout")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Live Chord & Note Detection")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Button(action: toggleListening) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 60))
                    .foregroundColor(backgroundColor)
                    .padding(40)
                    .background(Circle().fill(.white))
                    .shadow(color: accentColor.opacity(0.8), radius: 20, x: 0, y: 0)
                    .scaleEffect(pulse ? 1.1 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Listening View
    var listeningView: some View {
        VStack(spacing: 20) {
            // Song Info Display has been removed
            
            Text("Let's Scout!")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .frame(height: 80) // Reserve space
            
            // Chord & Note Info Card
            if chorder.currentChord != nil || chorder.currentNote != nil {
                VStack(spacing: 15) {
                    if let chord = chorder.currentChord {
                        HStack {
                            Text(chord.displayName)
                                .font(.system(size: 72, weight: .bold, design: .monospaced))
                                .contentTransition(.interpolate)
                                .foregroundColor(.white)
                            
                            Text(String(format: "%.0f%%", chord.confidence * 100))
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    if let note = chorder.currentNote {
                        HStack {
                            Text("Note: \(note.name)")
                                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                                .foregroundColor(accentColor)
                                .contentTransition(.interpolate)
                        
                            Text(String(format: "%.1f Hz", note.frequency))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding()
                .background(.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.2), lineWidth: 1))
            }
            
            PianoKeyboardView(activeMIDINotes: Set(chorder.currentNote.map { [$0.midi] } ?? []))
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.3), radius: 8)
            
            Spacer()
            
            AudioVisualizerView(audioManager: audio)
                .frame(height: 80)
            
            Spacer()
            
            Button("Stop", role: .destructive, action: toggleListening)
                .buttonStyle(.bordered)
                .padding(.bottom)
        }
        .padding()
        .animation(.spring(), value: chorder.currentChord)
    }

    // MARK: - Logic
    private func requestMicPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("🎤 Microphone permission granted.")
            } else {
                print("🎤 Microphone permission denied.")
            }
        }
    }
    
    private func toggleListening() {
        if isListening {
            audio.stop()
            isListening = false
        } else {
            do {
                try audio.startListening { buffer, when in
                    analysisQueue.async {
                        if let bufferCopy = buffer.copy() as? AVAudioPCMBuffer {
                            // Only process for chords and notes now
                            chorder.process(buffer: bufferCopy)
                        }
                    }
                }
                isListening = true
            } catch {
                print("Mic start error: \(error)")
                isListening = false
            }
        }
    }
}

// MARK: - Audio Visualizer Component
struct AudioVisualizerView: View {
    @ObservedObject var audioManager: AudioManager
    private let barCount = 20
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom))
                    .frame(height: calculateBarHeight(for: index))
            }
        }
        .animation(.easeOut(duration: 0.05), value: audioManager.audioLevel)
    }
    
    private func calculateBarHeight(for index: Int) -> CGFloat {
        let normalizedLevel = CGFloat(max(0, audioManager.audioLevel))
        let curvedLevel = pow(normalizedLevel, 0.7)
        let centerIndex = CGFloat(barCount / 2)
        let distanceFromCenter = abs(CGFloat(index) - centerIndex)
        let scale = max(0, 1.0 - distanceFromCenter / centerIndex) * 0.8 + 0.2
        return max(5, curvedLevel * 80 * scale)
    }
}

#Preview {
    ContentView()
}
