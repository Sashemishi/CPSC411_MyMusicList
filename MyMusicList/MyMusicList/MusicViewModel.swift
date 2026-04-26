import Foundation
import SwiftUI
import Combine

class MusicViewModel: ObservableObject {
    @Published var savedSongs: [MusicItem] = []
    @Published var lyricsText: [UUID: String] = [:]
    
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
    
    func lyrics(id: UUID, artist: String, title: String) {
        let url = URL(string: "https://api.lyrics.ovh/v1/\(artist)/\(title)")!
        let request = URLRequest(url: url)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          if let response = response {
            print(response)

            if let data = data, let body = String(data: data, encoding: .utf8) {
                if let decodedData = try? JSONDecoder().decode(Lyrics.self, from: data) {
                    DispatchQueue.main.async {
                        self.lyricsText[id] = decodedData.lyrics
                    }
                } else {
                    DispatchQueue.main.async {
                        self.lyricsText[id] = "Lyrics not found."
                    }
                }
                }
          } else {
            print(error ?? "Unknown error")
            self.lyricsText[id] = "Unknown error"
          }
        }
        
        task.resume()
        
    }
    
}
