import SwiftUI
import AVFoundation

func loadMusicFromBundle() -> [MusicItem] {
    guard let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) else {
        return []
    }

    return urls.map { url in
        let filename = url.deletingPathExtension().lastPathComponent
        let asset = AVURLAsset(url: url)
        let metadata = asset.commonMetadata
        
        let titleItems = AVMetadataItem.metadataItems(from: metadata,
                                                      filteredByIdentifier: .commonIdentifierTitle)
        let artistItems = AVMetadataItem.metadataItems(from: metadata,
                                                      filteredByIdentifier: .commonIdentifierArtist)
        let title = titleItems.first?.stringValue ?? filename
        let artist = artistItems.first?.stringValue ?? "Unknown Artist"
        return MusicItem(
            title: title,
            artist: artist,
        )
    }
}

struct SearchView: View {
    @EnvironmentObject var viewModel: MusicViewModel

    @State private var musicList: [MusicItem] = []
    @State private var showAddToPlaylistSheet: Bool = false
    @State private var selectedSong: MusicItem?

    var body: some View {
        List(musicList) { music in
            VStack(alignment: .leading, spacing: 8) {
                Text(music.title)
                    .font(.headline)

                Text(music.artist)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack(spacing: 12) {
                    Menu("Add to Playlist") {
                        if viewModel.playlists.isEmpty {
                            Button("No playlists yet") {}
                                .disabled(true)
                        } else {
                            ForEach(viewModel.playlists) { playlist in
                                Button(playlist.name) {
                                    add(music, to: playlist)
                                }
                            }
                        }
                        Divider()
                        Button("Choose…") {
                            selectedSong = music
                            showAddToPlaylistSheet = true
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .navigationTitle("Search")
        .onAppear {
            musicList = loadMusicFromBundle()
        }
        .sheet(isPresented: $showAddToPlaylistSheet) {
            AddToPlaylistSheet(
                playlists: viewModel.playlists,
                onSelect: { playlist in
                    if let song = selectedSong {
                        add(song, to: playlist)
                    }
                    selectedSong = nil
                }
            )
        }
    }

    private func add(_ song: MusicItem, to playlist: Playlist) {
        // Prefer a view model API if available
        if let addMethod = (viewModel as AnyObject) as? (MusicItem, Playlist) -> Void {
            // This branch is unlikely; we keep a direct path below.
            addMethod(song, playlist)
        } else {
            // Fallback: mutate via viewModel by locating the playlist and appending
            if let index = viewModel.playlists.firstIndex(where: { $0.id == playlist.id }) {
                if !viewModel.playlists[index].songs.contains(where: { $0.id == song.id }) {
                    viewModel.playlists[index].songs.append(song)
                }
            }
        }
    }
}

private struct AddToPlaylistSheet: View {
    var playlists: [Playlist]
    var onSelect: (Playlist) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(playlists) { playlist in
                Button(action: {
                    onSelect(playlist)
                    dismiss()
                }) {
                    HStack {
                        Text(playlist.name)
                        Spacer()
                        Text("\(playlist.songs.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

#Preview {
    let viewModel = MusicViewModel()

    return NavigationStack {
        SearchView()
            .environmentObject(viewModel)
    }
}
