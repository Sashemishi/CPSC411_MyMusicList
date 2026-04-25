import SwiftUI


struct SearchView: View {
    @EnvironmentObject var viewModel: MusicViewModel
    
    let sampleMusic = [
        MusicItem(title: "It's Going Down Now", artist: "Azumi Takashi"),
        MusicItem(title: "Inside", artist: "HOYO-MiX, Chevy, Robin"),
        MusicItem(title: "One Way", artist: "Twenty One Pilots")
    ]
    
    var body: some View {
        
        List(sampleMusic) { music in
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
    }
}

#Preview {
    SearchView()
}
