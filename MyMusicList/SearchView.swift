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
                    .font(.system(size:30, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Group {
                    if isLoading {
                        ProgressView("Searching...")
                            .padding()
                    } else if filteredMusic.isEmpty {
                        VStack(spacing: 5) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                            
                            Text("No songs found")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Search for a song, artist, or album.")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        
                    } else {
                        List(filteredMusic) { music in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(music.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(music.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Button("Add to MyList") {
                                    viewModel.addSong(music)
                                        
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColors.accent)
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(Color.clear)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
                .background(AppColors.background)
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
