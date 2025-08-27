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

#Preview {
    SongDetailView(
        song: SongInfo(
            title: "Guru ka Darshan",
            artist: "Radha Soami",
            appleMusicURL: URL(string: "https://music.apple.com/us/album/shape-of-you/1193701079?i=1193701359")
        ),
        lyrics: """
        Guru ka darshan dekh dekh jeevan
        Guru ke charan dhoye dhoye peevan...
        """
    )
}
