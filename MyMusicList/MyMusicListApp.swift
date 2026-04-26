import SwiftUI
import Combine

@main
struct MyMusicListApp: App {
    @StateObject var viewModel = MusicViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
