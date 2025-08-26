import Foundation

struct SongInfo: Equatable {
    var title: String
    var artist: String
    var artworkURL: URL?
    var appleMusicURL: URL?
    var isrc: String?
}
