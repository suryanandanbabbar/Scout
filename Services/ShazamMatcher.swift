import Foundation
import ShazamKit
import AVFoundation

final class ShazamMatcher: NSObject, ObservableObject, SHSessionDelegate {
    @Published var lastMatch: SongInfo?
    
    private let session = SHSession()
    private var signatureGenerator = SHSignatureGenerator()
    
    override init() {
        super.init()
        session.delegate = self
    }
    
    func process(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        do {
            try signatureGenerator.append(buffer, at: time)
            
            let signature = signatureGenerator.signature()
            if signature.duration >= 5 {
                session.match(signature)
                
                // Reset by creating a new generator
                signatureGenerator = SHSignatureGenerator()
            }
        } catch {
            print("Signature append error: \(error)")
        }
    }
    
    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let item = match.mediaItems.first else { return }
        let title = item.title ?? "Unknown"
        let artist = item.artist ?? ""
        let artwork = item.artworkURL
        let amURL = item.appleMusicURL
        let isrc = item.isrc
        DispatchQueue.main.async {
            self.lastMatch = SongInfo(title: title, artist: artist, artworkURL: artwork, appleMusicURL: amURL, isrc: isrc)
        }
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        // No-op; we try again on next chunk
    }
}
