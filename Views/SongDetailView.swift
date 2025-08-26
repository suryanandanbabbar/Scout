import SwiftUI

struct SongDetailView: View {
    let song: SongInfo?
    let lyrics: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let s = song {
                    Text(s.title).font(.title).bold()
                    Text(s.artist).font(.title3).foregroundStyle(.secondary)
                    if let url = s.appleMusicURL {
                        Link("Open in Apple Music", destination: url)
                    }
                }
                Divider()
                Text("Lyrics").font(.headline)
                Text(lyrics.isEmpty ? "(No lyrics available)" : lyrics)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .navigationTitle("Details")
    }
}
