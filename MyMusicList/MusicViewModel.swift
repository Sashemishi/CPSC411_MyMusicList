import Foundation
import SwiftUI
import Combine

class MusicViewModel: ObservableObject {
    @Published var savedSongs: [MusicItem] = [] {
        didSet {
            saveSongs()
            syncCurrentSongWithAvailableSongs()
        }
    }

    @Published var lyricsText: [UUID: String] = [:]

    @Published var playlists: [Playlist] = [] {
        didSet {
            savePlaylists()
        }
    }

    @Published var currentSong: MusicItem?
    @Published var currentQueue: [MusicItem] = []
    @Published var isPlayerPresented = false

    private let playlistsKey = "savedPlaylists"

    init() {
        loadSongs()
        loadPlaylists()
    }

    // MARK: - Playlist Management

    func createPlaylist(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        playlists.append(Playlist(name: trimmed))
    }

    func deletePlaylist(at offsets: IndexSet) {
        // Prevent deleting the last remaining playlist
        let remaining = playlists.count - offsets.count
        guard remaining >= 1 else { return }
        playlists.remove(atOffsets: offsets)
    }

    func addSong(_ music: MusicItem, toPlaylistID playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        if !playlists[index].songs.contains(where: { $0.title == music.title && $0.artist == music.artist }) {
            playlists[index].songs.append(music)
        }
    }

    func deleteSong(from playlistID: UUID, at offsets: IndexSet) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[index].songs.remove(atOffsets: offsets)
    }

    private func savePlaylists() {
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: playlistsKey)
        }
    }

    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data),
           !decoded.isEmpty {
            playlists = decoded
        } else {
            // Default playlist on first launch
            playlists = [Playlist(name: "MyList")]
        }
    }

    // MARK: - Existing Song Management

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

    // MARK: - Playback State

    func presentPlayback(for song: MusicItem, queue: [MusicItem]? = nil) {
        if let queue, !queue.isEmpty {
            currentQueue = queue
        } else if savedSongs.contains(where: { $0.id == song.id }) {
            currentQueue = savedSongs
        } else {
            currentQueue = [song]
        }

        currentSong = song
        isPlayerPresented = true
    }

    func dismissPlayback() {
        isPlayerPresented = false
    }

    func selectPlaybackSong(_ song: MusicItem) {
        currentSong = song
    }

    private func syncCurrentSongWithAvailableSongs() {
        guard let currentSong else { return }

        if let savedMatch = savedSongs.first(where: { $0.id == currentSong.id }) {
            self.currentSong = savedMatch
        } else if currentQueue.contains(where: { $0.id == currentSong.id }) {
            return
        } else {
            self.currentSong = nil
            isPlayerPresented = false
        }

        currentQueue.removeAll { queuedSong in
            !savedSongs.contains(where: { $0.id == queuedSong.id })
        }
    }
}
