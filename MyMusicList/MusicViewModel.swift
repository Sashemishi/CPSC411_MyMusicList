import Foundation
import SwiftUI
import Combine

class MusicViewModel: ObservableObject {
    @Published var savedSongs: [MusicItem] = [] {
        didSet {
            saveSongs()
        }
    }

    @Published var lyricsText: [UUID: String] = [:]

    init() {
        loadSongs()
    }

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

    private func saveSongs() {
        if let encoded = try? JSONEncoder().encode(savedSongs) {
            UserDefaults.standard.set(encoded, forKey: "savedSongs")
        }
    }

    private func loadSongs() {
        if let data = UserDefaults.standard.data(forKey: "savedSongs"),
           let decoded = try? JSONDecoder().decode([MusicItem].self, from: data) {
            savedSongs = decoded
        }
    }

    func lyrics(id: UUID, artist: String, title: String) {
        let artistEncoded = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? artist
        let titleEncoded = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title

        guard let url = URL(string: "https://api.lyrics.ovh/v1/\(artistEncoded)/\(titleEncoded)") else {
            lyricsText[id] = "Invalid URL."
            return
        }

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.lyricsText[id] = "Error: \(error.localizedDescription)"
                }
                return
            }

            if let data = data,
               let decodedData = try? JSONDecoder().decode(Lyrics.self, from: data) {
                DispatchQueue.main.async {
                    self.lyricsText[id] = decodedData.lyrics
                }
            } else {
                DispatchQueue.main.async {
                    self.lyricsText[id] = "Lyrics not found."
                }
            }
        }.resume()
    }
}
