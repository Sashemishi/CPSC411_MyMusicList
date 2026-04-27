import SwiftUI

struct MyListView: View {
    @EnvironmentObject var viewModel: MusicViewModel
    @State private var expandedSongID: UUID?
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Custom title
                Text("Your List")
                    .font(.system(size:30, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                List {
                    if viewModel.savedSongs.isEmpty {
                        VStack(spacing: 10) {
                            
                            Image(systemName: "music.note.list")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                            
                            Text("No songs added yet")
                                .font(.headline)
                                .foregroundColor(.white)
                                .bold()
                            
                            Text("Search and add music to begin.")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowBackground(AppColors.accent)
                    } else {
                        ForEach(viewModel.savedSongs) { music in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(music.title)
                                    .font(.headline)
                                Text(music.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Button("Tap to view Lyrics..") {
                                    if expandedSongID == music.id {
                                        expandedSongID = nil
                                    } else {
                                        expandedSongID = music.id
                                        viewModel.lyrics(id: music.id, artist: music.artist, title: music.title)
                                    }
                                }
                                if expandedSongID == music.id {
                                    Text(viewModel.lyricsText[music.id] ?? "Loading...")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: viewModel.deleteSong)
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("My List")
                .toolbar {
                    EditButton()
                }
            }
        }
    }
}

#Preview {
    MyListView()
        .environmentObject(MusicViewModel())
}
