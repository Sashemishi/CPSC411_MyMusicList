import Foundation
import SwiftUI
import Combine

class MusicViewModel: ObservableObject {
    @Published var savedSongs: [MusicItem] = []
}
