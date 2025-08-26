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
                        Text(shazam.lastMatch?.title ?? "Listening...")
                            .font(.title2).bold()
                        Text(shazam.lastMatch?.artist ?? "")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(isListening ? "Stop" : "Listen") {
                        toggleListening()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if let chord = chorder.currentChord {
                    HStack {
                        Text("Chord:")
                        Text(chord.displayName).font(.title).bold()
                        Spacer()
                        Text(String(format: "conf %.2f", chord.confidence))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                if let note = chorder.currentNote {
                    HStack {
                        Text("Note:")
                        Text(note.name).font(.title3).bold()
                        Spacer()
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
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scout")
            .task {
                await lyrics.requestAuthorization()
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
                    // Feed both detectors
                    shazam.process(buffer: buffer, at: when)
                    chorder.process(buffer: buffer)
                    if let song = shazam.lastMatch {
                        Task { await lyrics.fetchLyricsIfAvailable(title: song.title, artist: song.artist) }
                    }
                }
                isListening = true
            } catch {
                print("Mic start error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
