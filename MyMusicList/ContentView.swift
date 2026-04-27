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

// Define app's colors as constants
enum AppColors {
    static let background = Color(hex: 0x1E2A38)
    static let tileBackground = Color(hex: 0x2A3A4D)
    static let tileBorder = Color(hex:0x3A4D63)
    static let accent = Color(hex: 0x4FC3F7)
    static let primaryText = Color(hex: 0xF5F7FA)
    static let secondaryText = Color(hex: 0xC8D4E0)
    static let mutedText = Color(hex: 0x8FA3B8)
}

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

            if let currentSong = musicViewModel.currentSong {
                MiniPlayerView(song: currentSong)
                    .environmentObject(musicViewModel)
            }
            
            // Persistent bottom bar
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

struct BottomBar: View {
    @Binding var selectedTab: ContentView.Tab
    
    var body: some View {
        HStack {
            BottomBarButton(
                icon: "house.fill",
                label: "Home",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }
            
            BottomBarButton(
                icon: "magnifyingglass",
                label: "Search",
                isSelected: selectedTab == .search
            ) {
                selectedTab = .search
            }
            
            BottomBarButton(
                icon: "music.note.list",
                label: "MyLists",
                isSelected: selectedTab == .myList
            ) {
                selectedTab = .myList
            }
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
                    .font(.system(size:30))
                Text(label)
                    .font(.caption)
                    .foregroundColor(AppColors.mutedText)
            }
            .foregroundColor(isSelected ? AppColors.accent : AppColors.mutedText)
            .frame(maxWidth: .infinity)
        }
    }
}

struct MiniPlayerView: View {
    @EnvironmentObject var viewModel: MusicViewModel

    let song: MusicItem

    var body: some View {
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

                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppColors.tileBackground)
        }
        .buttonStyle(.plain)
    }
}

// Some temporary homeview (can move to a separate file later)
struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    // Custom title
                    Text("MyMusicList")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // songs, details, etc go here
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationBarHidden(true)  // hide system nav bar entirely
        }
    }
}

#Preview {
    ContentView()
}
