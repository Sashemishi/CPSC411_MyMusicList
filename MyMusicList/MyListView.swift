import SwiftUI

struct MyListView: View {
    @EnvironmentObject var viewModel: MusicViewModel
    @State private var showingNewPlaylistAlert = false
    @State private var newPlaylistName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    // Custom title row with + button
                    HStack {
                        Text("MyLists")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(AppColors.primaryText)

                        Spacer()

                        Button {
                            newPlaylistName = ""
                            showingNewPlaylistAlert = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    List {
                        if viewModel.playlists.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "music.note.list")
                                    .font(.largeTitle)
                                    .foregroundColor(AppColors.primaryText)

                                Text("No playlists yet")
                                    .font(.headline)
                                    .foregroundColor(AppColors.primaryText)
                                    .bold()

                                Text("Tap + to create your first playlist.")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .listRowBackground(AppColors.tileBackground)
                        } else {
                            ForEach(viewModel.playlists) { playlist in
                                NavigationLink(destination: PlaylistDetailView(playlistID: playlist.id)) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "music.note.list")
                                            .font(.system(size: 22))
                                            .foregroundColor(AppColors.accent)
                                            .frame(width: 32)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(playlist.name)
                                                .font(.system(size: 20))
                                                .foregroundColor(AppColors.primaryText)

                                            Text("\(playlist.songs.count) song\(playlist.songs.count == 1 ? "" : "s")")
                                                .font(.subheadline)
                                                .foregroundColor(AppColors.secondaryText)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(AppColors.tileBackground)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if viewModel.playlists.count > 1 {
                                        Button(role: .destructive) {
                                            if let index = viewModel.playlists.firstIndex(where: { $0.id == playlist.id }) {
                                                viewModel.deletePlaylist(at: IndexSet(integer: index))
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .alert("New Playlist", isPresented: $showingNewPlaylistAlert) {
                TextField("Playlist name", text: $newPlaylistName)
                Button("Cancel", role: .cancel) {
                    newPlaylistName = ""
                }
                Button("Create") {
                    viewModel.createPlaylist(name: newPlaylistName)
                    newPlaylistName = ""
                }
            } message: {
                Text("Enter a name for your new playlist.")
            }
        }
    }
}

struct PlaylistDetailView: View {
    @EnvironmentObject var viewModel: MusicViewModel
    let playlistID: UUID
    @State private var expandedSongID: UUID?

    private var playlist: Playlist? {
        viewModel.playlists.first(where: { $0.id == playlistID })
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Custom title
                Text(playlist?.name ?? "Playlist")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                List {
                    if let songs = playlist?.songs, !songs.isEmpty {
                        ForEach(songs) { music in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(music.title)
                                            .font(.system(size: 20))
                                            .foregroundColor(AppColors.primaryText)

                                        Text(music.artist)
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.secondaryText)
                                    }

                                    Spacer()

                                    Button {
                                        viewModel.presentPlayback(for: music, queue: songs)
                                    } label: {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(AppColors.accent)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button(expandedSongID == music.id ? "Hide Lyrics" : "Tap to view Lyrics..") {
                                    if expandedSongID == music.id {
                                        expandedSongID = nil
                                    } else {
                                        expandedSongID = music.id
                                        viewModel.lyrics(id: music.id, artist: music.artist, title: music.title)
                                    }
                                }
                                .foregroundColor(AppColors.accent)

                                if expandedSongID == music.id {
                                    ScrollView {
                                        Text(viewModel.lyricsText[music.id] ?? "Loading...")
                                            .foregroundColor(AppColors.primaryText)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 4)
                                    }
                                    .frame(maxHeight: 300)
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(AppColors.tileBackground)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let songs = playlist?.songs,
                                       let index = songs.firstIndex(where: { $0.id == music.id }) {
                                        viewModel.deleteSong(from: playlistID, at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "music.note.list")
                                .font(.largeTitle)
                                .foregroundColor(AppColors.primaryText)

                            Text("No songs added yet")
                                .font(.headline)
                                .foregroundColor(AppColors.primaryText)
                                .bold()

                            Text("Search and add music to begin.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowBackground(AppColors.tileBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MyListView()
        .environmentObject(MusicViewModel())
}
