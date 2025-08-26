import Foundation
import MusicKit

@MainActor
final class LyricsService: ObservableObject {
    @Published var lyricsText: String = ""
    @Published var isAuthorized: Bool = false
    
    // TODO: Set your Apple Music developer token here for catalog requests (server-side in production)
    private let developerToken: String? = nil
    
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        isAuthorized = status == .authorized
    }
    
    func fetchLyricsIfAvailable(title: String, artist: String) async {
        lyricsText = ""
        guard isAuthorized else {
            lyricsText = "Apple Music not authorized. Lyrics unavailable."
            return
        }
        guard let devToken = developerToken else {
            lyricsText = "Developer token missing. Provide token in LyricsService.swift."
            return
        }
        do {
            MusicAuthorization.currentStatus // access to ensure entitlement
            
            var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [Song.self])
            request.limit = 1
            let response = try await request.response()
            guard let song = response.songs.first else {
                lyricsText = "Lyrics not found."; return
            }
            // MusicKit does not expose full lyrics text in all regions; show preview via editorialNotes if present
            if let lyricSnippet = song.editorialNotes?.standard {
                lyricsText = lyricSnippet
            } else {
                lyricsText = "Lyrics access not available for this track/region."
            }
        } catch {
            lyricsText = "Lyrics error: \(error.localizedDescription)"
        }
    }
}
