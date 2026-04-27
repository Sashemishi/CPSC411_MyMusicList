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
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Custom title
                Text("Search")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                List {
                    if isLoading {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Searching...")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowBackground(AppColors.tileBackground)
                    } else if filteredMusic.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(AppColors.primaryText)

                            Text("No songs found")
                                .font(.headline)
                                .foregroundColor(AppColors.primaryText)
                                .bold()

                            Text("Search for a song, artist, or album.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowBackground(AppColors.tileBackground)
                    } else {
                        ForEach(filteredMusic) { music in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(music.title)
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.primaryText)

                                Text(music.artist)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.secondaryText)

                                Menu {
                                    ForEach(viewModel.playlists) { playlist in
                                        Button(playlist.name) {
                                            viewModel.addSong(music, toPlaylistID: playlist.id)
                                        }
                                    }
                                } label: {
                                    Text("Add to MyList")
                                        .foregroundColor(AppColors.accent)
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(AppColors.tileBackground)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search songs or artists")
                .onSubmit(of: .search) {
                    searchMusic()
                }
                .onAppear {
                    musicList = loadSampleMusic()
                }
            }
        }
        .navigationBarHidden(true)
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
