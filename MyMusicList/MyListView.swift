import SwiftUI

struct MyListView: View {
    @EnvironmentObject var viewModel: MusicViewModel
    @State private var expandedSongID: UUID?
    
    var body: some View {
        List {
            if viewModel.savedSongs.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                        .foregroundColor(.gray)

                    Text("No songs added yet")
                        .font(.headline)

                    Text("Search and add music to begin.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
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
        .navigationTitle("My List")
        .toolbar {
            EditButton()
        }
    }
}

#Preview {
    MyListView()
        .environmentObject(MusicViewModel())
}
