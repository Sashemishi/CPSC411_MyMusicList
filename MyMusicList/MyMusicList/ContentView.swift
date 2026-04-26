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
    static let accent = Color(hex: 0xFF6B6B)
}


struct ContentView: View {
    let MAX_TILE_WIDTH = 100.0
    let MAX_TILE_HEIGHT = 50.0

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    HStack(spacing: 50) {
                        Button(action: {}) {
                            VStack(spacing: 4) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 32))
                                Text("Home")
                            }
                            .foregroundStyle(.white)
                            .frame(width: 80)
                        }

                        NavigationLink(destination: SearchView()) {
                            VStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                Text("Search")
                            }
                            .foregroundStyle(.white)
                            .frame(width: 80)
                        }

                        NavigationLink(destination: MyListView()) {
                            VStack(spacing: 4) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 32))
                                Text("Your List")
                            }
                            .foregroundStyle(.white)
                            .frame(width: 80)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
