import Foundation
import ShazamKit
import AVFoundation

final class ShazamMatcher: NSObject, ObservableObject, SHSessionDelegate {
    @Published var lastMatch: SongInfo?

    private let session = SHSession()

    override init() {
        super.init()
        self.session.delegate = self
    }

    func process(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        // Live streaming match (built-in Shazam catalog)
        session.matchStreamingBuffer(buffer, at: time)
    }

    // MARK: - SHSessionDelegate
    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let item = match.mediaItems.first else { return }
        DispatchQueue.main.async {
            self.lastMatch = SongInfo(
                title: item.title ?? "Unknown",
                artist: item.artist ?? "",
                artworkURL: item.artworkURL,
                appleMusicURL: item.appleMusicURL,
                isrc: item.isrc
            )
        }
    }

    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        print("❌ No match found: \(error?.localizedDescription ?? "none")")
    }
}
