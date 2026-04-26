import SwiftUI

struct SearchView: View {
    @EnvironmentObject var viewModel: MusicViewModel

    @State private var musicList: [MusicItem] = []
    @State private var searchText = ""

    var filteredMusic: [MusicItem] {
        if searchText.isEmpty {
            return musicList
        }

        return musicList.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredMusic.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)

                        Text("No songs found")
                            .font(.headline)

                        Text("Try another search or add music files later.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(filteredMusic) { music in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(music.title)
                                .font(.headline)

                            Text(music.artist)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Button("Add to MyList") {
                                viewModel.addSong(music)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search songs or artists")
            .onAppear {
                musicList = loadMusicFromBundle()
            }
        }
    }

    func loadMusicFromBundle() -> [MusicItem] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) else {
            return []
        }

        return urls.map { url in
            MusicItem(
                title: url.deletingPathExtension().lastPathComponent,
                artist: "Unknown Artist"
            )
        }
    }
}

#Preview {
    NavigationStack {
        SearchView()
            .environmentObject(MusicViewModel())
    }
}
