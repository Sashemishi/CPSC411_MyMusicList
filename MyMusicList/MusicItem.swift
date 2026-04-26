import Foundation
import SwiftUI

struct MusicItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let album: String?
    let musicBrainzID: String?
    let coverURL: String?

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String? = nil,
        musicBrainzID: String? = nil,
        coverURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.musicBrainzID = musicBrainzID
        self.coverURL = coverURL
    }
}

struct Lyrics: Decodable {
    let lyrics: String
}

