import Foundation
import SwiftUI
import Combine

class MusicViewModel: ObservableObject {
    @Published var savedSongs: [MusicItem] = []
    
    
    func addSong(_ music: MusicItem) {
        if !savedSongs.contains(where: { $0.title == music.title && $0.artist == music.artist }) {
            savedSongs.append(music)
        }
    }

    func deleteSong(at offsets: IndexSet) {
        savedSongs.remove(atOffsets: offsets)
    }

    func isSaved(_ music: MusicItem) -> Bool {
        savedSongs.contains(where: { $0.title == music.title && $0.artist == music.artist })
    }
}
