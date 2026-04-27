import SwiftUI

// Looks for {title}.jpg or {title}.png in the bundle alongside each .mp3
func loadMusicFromBundle() -> [MusicItem] {
    guard let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) else {
        return []
    }

    return urls.map { url in
        let filename = url.deletingPathExtension().lastPathComponent

        // Match a cover image with the same base filename
        let coverURL: String? = {
            if let jpg = Bundle.main.url(forResource: filename, withExtension: "jpg") {
                return jpg.absoluteString
            }
            if let png = Bundle.main.url(forResource: filename, withExtension: "png") {
                return png.absoluteString
            }
            return nil
        }()

        return MusicItem(
            title: filename,
            artist: "Unknown Artist",
            coverURL: coverURL
        )
    }
}

struct SearchView: View {
    @EnvironmentObject var viewModel: MusicViewModel

    @State private var musicList: [MusicItem] = []
    @State private var showAddToPlaylistSheet: Bool = false
    @State private var selectedSong: MusicItem?

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            List(musicList) { music in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(music.title)
                                .font(.headline)
                                .foregroundColor(AppColors.primaryText)

                            Text(music.artist)
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                        }

                        Spacer()

                        Button {
                            viewModel.presentPlayback(for: music, queue: musicList)
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.accent)
                        }
                        .buttonStyle(.plain)
                    }

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
                        .tint(AppColors.accent)
                        .buttonStyle(.borderless)
                    }
                }
                .listRowBackground(AppColors.tileBackground)
            }
            .scrollContentBackground(.hidden)
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
        if let index = viewModel.playlists.firstIndex(where: { $0.id == playlist.id }) {
            if !viewModel.playlists[index].songs.contains(where: { $0.id == song.id }) {
                viewModel.playlists[index].songs.append(song)
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
