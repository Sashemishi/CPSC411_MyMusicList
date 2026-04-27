//  CPSC-411 App Development
//  MyMusicList
//
//  Matthew Choi
//  Allison Yu
//  Alex Jardon
//  Tony Lin
//  Howard Wu
//  Allen Chau

import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - App Colors

enum AppColors {
    static let background    = Color(hex: 0x1E2A38)
    static let tileBackground = Color(hex: 0x2A3A4D)
    static let tileBorder    = Color(hex: 0x3A4D63)
    static let accent        = Color(hex: 0x4FC3F7)
    static let primaryText   = Color(hex: 0xF5F7FA)
    static let secondaryText = Color(hex: 0xC8D4E0)
    static let mutedText     = Color(hex: 0x8FA3B8)
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var musicViewModel = MusicViewModel()
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, search, myList
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .home:
                    HomeView()
                case .search:
                    SearchView()
                case .myList:
                    MyListView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Mini player sits above the tab bar when a song is active
            if let currentSong = musicViewModel.currentSong {
                MiniPlayerView(song: currentSong)
                    .environmentObject(musicViewModel)
            }

            BottomBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(musicViewModel)
        .fullScreenCover(isPresented: $musicViewModel.isPlayerPresented) {
            PlaybackView(song: musicViewModel.currentSong)
                .environmentObject(musicViewModel)
        }
    }
}

// MARK: - Bottom Bar

struct BottomBar: View {
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
        HStack {
            BottomBarButton(icon: "house.fill",       label: "Home",    isSelected: selectedTab == .home)    { selectedTab = .home }
            BottomBarButton(icon: "magnifyingglass",  label: "Search",  isSelected: selectedTab == .search)  { selectedTab = .search }
            BottomBarButton(icon: "music.note.list",  label: "MyLists", isSelected: selectedTab == .myList)  { selectedTab = .myList }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(AppColors.background)
    }
}

struct BottomBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                Text(label)
                    .font(.caption)
                    .foregroundColor(AppColors.mutedText)
            }
            .foregroundColor(isSelected ? AppColors.accent : AppColors.mutedText)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Mini Player

struct MiniPlayerView: View {
    @EnvironmentObject var viewModel: MusicViewModel
    @StateObject private var playbackController = PlaybackController.shared

    let song: MusicItem

    var body: some View {
        HStack(spacing: 12) {
            // Tapping the song info opens the full player
            Button {
                viewModel.presentPlayback(for: song, queue: viewModel.currentQueue)
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppColors.accent.opacity(0.35))
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundColor(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.headline)
                            .foregroundColor(AppColors.primaryText)
                            .lineLimit(1)

                        Text(playbackController.isPlaying ? "Playing" : "Paused")
                            .font(.caption)
                            .foregroundColor(AppColors.accent)

                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Play / pause toggle
            Button {
                if !playbackController.isPrepared(for: song) {
                    playbackController.prepare(song: song)
                }
                playbackController.togglePlayback()
            } label: {
                Image(systemName: playbackController.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.tileBackground)
    }
}

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var viewModel: MusicViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // App title
                        Text("MyMusicList")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)

                        // Recent Playlists
                        Text("Recent Playlists")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)

                        RecentPlaylistsRow()
                            .padding(.top, 8)

                        // Recent Songs
                        Text("Recent Songs")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 8)

                        RecentSongsList()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Recent Playlists Row

struct RecentPlaylistsRow: View {
    @EnvironmentObject var viewModel: MusicViewModel

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 12
            let horizontalPadding: CGFloat = 20
            let visibleTiles: CGFloat = 3
            let tileSize = (geo.size.width - horizontalPadding * 2 - spacing * (visibleTiles - 1)) / visibleTiles

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    if viewModel.playlists.isEmpty {
                        Text("No playlists yet")
                            .font(.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                            .frame(height: tileSize)
                    } else {
                        ForEach(viewModel.playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlistID: playlist.id)) {
                                PlaylistTile(playlist: playlist, size: tileSize)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
        // Fixed height: tile + label
        .frame(height: 170)
    }
}

// MARK: - Playlist Tile

struct PlaylistTile: View {
    let playlist: Playlist
    let size: CGFloat

    private var coverURL: URL? {
        guard let urlString = playlist.songs.first?.coverURL else { return nil }
        return URL(string: urlString)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.tileBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppColors.tileBorder, lineWidth: 1)
                    )

                if let coverURL {
                    AsyncImage(url: coverURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: size, height: size)
                                .clipped()
                        default:
                            Image(systemName: "music.note.list")
                                .font(.system(size: size * 0.4))
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "music.note.list")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(AppColors.accent)
                }
            }
            .frame(width: size, height: size)

            Text(playlist.name)
                .font(.caption)
                .foregroundColor(AppColors.primaryText)
                .lineLimit(1)
                .frame(width: size, alignment: .leading)
        }
    }
}

// MARK: - Recent Songs List

struct RecentSongsList: View {
    @EnvironmentObject var viewModel: MusicViewModel

    var body: some View {
        LazyVStack(spacing: 8) {
            if viewModel.recentlyPlayed.isEmpty {
                Text("No recent songs")
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentlyPlayed) { song in
                    RecentSongRow(song: song)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Recent Song Row

struct RecentSongRow: View {
    let song: MusicItem

    private var coverURL: URL? {
        guard let urlString = song.coverURL else { return nil }
        return URL(string: urlString)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Cover / placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.background)

                if let coverURL {
                    AsyncImage(url: coverURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                        default:
                            Image(systemName: "music.note")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "music.note")
                        .foregroundColor(AppColors.accent)
                }
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(10)
        .background(AppColors.tileBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.tileBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
