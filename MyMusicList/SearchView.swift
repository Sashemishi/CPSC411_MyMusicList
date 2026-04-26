import SwiftUI

struct SearchView: View {
    @EnvironmentObject var viewModel: MusicViewModel

    @State private var musicList: [MusicItem] = []
    @State private var searchText = ""
    @State private var isLoading = false

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
                if isLoading {
                    ProgressView("Searching...")
                        .padding()
                } else if filteredMusic.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)

                        Text("No songs found")
                            .font(.headline)

                        Text("Search for a song, artist, or album.")
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
            .onSubmit(of: .search) {
                searchMusic()
            }
            .onAppear {
                musicList = loadSampleMusic()
            }
        }
    }

    func searchMusic() {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            musicList = loadSampleMusic()
            return
        }

        Task {
            do {
                isLoading = true

                let service = MusicBrainzService()
                let results = try await service.searchSongs(query: trimmedSearch)

                musicList = results
                isLoading = false
            } catch {
                print("Error fetching songs:", error)
                isLoading = false
            }
        }
    }

    func loadSampleMusic() -> [MusicItem] {
        return [
            MusicItem(title: "It's Going Down Now", artist: "Azumi Takahashi"),
            MusicItem(title: "Inside", artist: "HOYO-MiX, Chevy, Robin"),
            MusicItem(title: "One Way", artist: "Twenty One Pilots"),
            MusicItem(title: "Blinding Lights", artist: "The Weeknd"),
            MusicItem(title: "Levitating", artist: "Dua Lipa")
        ]
    }
}

#Preview {
    NavigationStack {
        SearchView()
            .environmentObject(MusicViewModel())
    }
}
