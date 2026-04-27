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
    static let accent = Color(hex: 0x64A1F8)
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
            
            // Persistent bottom bar
            BottomBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(musicViewModel)
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
                label: "Your List",
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
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
        }
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
                        .foregroundColor(.white)
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
