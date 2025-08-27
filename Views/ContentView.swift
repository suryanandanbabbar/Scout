import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audio = AudioManager.shared
    @StateObject private var shazam = ShazamMatcher()
    @StateObject private var chorder = ChordDetector()
    @StateObject private var lyrics = LyricsService()
    
    @State private var isListening = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
//                        Text(shazam.lastMatch?.title ?? "Listening...")
//                            .font(.title2).bold()
                        Text(shazam.lastMatch?.artist ?? "")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Button(action: {
                        toggleListening()
                    }) {
                        Image(systemName: "mic")
                            .font(.system(size: 30))
                            .foregroundColor(isListening ? .red : .blue) // red when recording
                            .padding()
                            .background(Circle().fill(Color.gray.opacity(0.2)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let chord = chorder.currentChord {
                    HStack {
                        Text("Chord:")
                        Text(chord.displayName).font(.title).bold()
                        Text(String(format: "conf %.2f", chord.confidence))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                if let note = chorder.currentNote {
                    HStack {
                        Text("Note:")
                        Text(note.name).font(.title3).bold()
                        Text(String(format: "%.1f Hz", note.frequency))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                
                PianoKeyboardView(activeMIDINotes: Set(chorder.currentNote.map { [$0.midi] } ?? []))
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 4)
                
                if let url = shazam.lastMatch?.artworkURL {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 160)
                    .cornerRadius(12)
                }
                
                NavigationLink("Details") {
                    SongDetailView(song: shazam.lastMatch, lyrics: lyrics.lyricsText)
                }
                .disabled(shazam.lastMatch == nil)
                
            }
            .padding()
            .navigationTitle("Scout")
            .task {
                await lyrics.requestAuthorization()
            }
            Spacer()
        }
    }
    
    private func toggleListening() {
        if isListening {
            // Stop microphone input
            audio.stop()
            isListening = false
            print("Stopped listening")
        } else {
            do {
                try audio.startListening { buffer, when in
                    // Feed both detectors
                    shazam.process(buffer: buffer, at: when)
                    chorder.process(buffer: buffer)

                    if let song = shazam.lastMatch {
                        Task {
                            await lyrics.fetchLyricsIfAvailable(title: song.title,
                                                                artist: song.artist)
                        }
                    }
                }
                isListening = true
                print("Started listening")
            } catch {
                print("Mic start error: \(error)")
                isListening = false
            }
        }
    }
}

#Preview {
    ContentView()
}
