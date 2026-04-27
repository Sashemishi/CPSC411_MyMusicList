import SwiftUI

func loadMusicFromBundle() -> [MusicItem] {
    guard let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) else {
        return []
    }

    return urls.map { url in
        let filename = url.deletingPathExtension().lastPathComponent
        
        return MusicItem(
            title: filename,
            artist: "Unknown Artist"
        )
    }
}

struct SearchView: View {
    @EnvironmentObject var viewModel: MusicViewModel
    @State private var musicList: [MusicItem] = []

    var body: some View {
          List(musicList) { music in
            VStack(alignment: .leading) {
                Text(music.title)
                    .font(.headline)

                Text(music.artist)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                

                Button("Add to MyList") {
                    viewModel.savedSongs.append(music)
                }
            }
        }
        .navigationTitle("Search")
        .onAppear {
            musicList = loadMusicFromBundle()
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
    let viewModel = MusicViewModel()
    
    return NavigationStack {
        SearchView()
            .environmentObject(viewModel)
    }
}
