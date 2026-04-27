import SwiftUI
import Combine
import AVFoundation

private final class PlaybackController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = PlaybackController()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var didFinishPlayback = false

    private var audioPlayer: AVAudioPlayer?
    private var currentSongID: UUID?

    func prepare(song: MusicItem) {
        guard currentSongID != song.id || audioPlayer == nil else {
            syncState()
            return
        }

        guard let url = audioURL(for: song) else {
            stop()
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()

            audioPlayer = player
            currentSongID = song.id
            didFinishPlayback = false
            syncState()
        } catch {
            stop()
        }
    }

    func play() {
        guard let audioPlayer else { return }
        didFinishPlayback = false
        audioPlayer.play()
        syncState()
    }

    func pause() {
        audioPlayer?.pause()
        syncState()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentSongID = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        didFinishPlayback = false
    }

    func seek(to time: Double) {
        guard let audioPlayer else { return }
        audioPlayer.currentTime = min(max(time, 0), audioPlayer.duration)
        didFinishPlayback = false
        syncState()
    }

    func refreshProgress() {
        syncState()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        syncState()
        didFinishPlayback = true
    }

    private func syncState() {
        guard let audioPlayer else {
            isPlaying = false
            currentTime = 0
            duration = 0
            return
        }

        isPlaying = audioPlayer.isPlaying
        currentTime = audioPlayer.currentTime
        duration = audioPlayer.duration
    }

    private func audioURL(for song: MusicItem) -> URL? {
        if let directURL = Bundle.main.url(forResource: song.title, withExtension: "mp3") {
            return directURL
        }

        let rootURLs = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) ?? []
        let musicURLs = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "Music") ?? []

        return (rootURLs + musicURLs).first {
            $0.deletingPathExtension().lastPathComponent == song.title
        }
    }
}

struct PlaybackView: View {
    @EnvironmentObject var viewModel: MusicViewModel
    @Environment(\.dismiss) private var dismiss
    let song: MusicItem?

    @State private var currentIndex = 0
    @State private var isPlaying = false
    @State private var isRepeatEnabled = false
    @State private var isDraggingSlider = false
    @State private var pendingSeekTime: Double = 0
    @StateObject private var playbackController = PlaybackController.shared

    private let playbackTimer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    init(song: MusicItem? = nil) {
        self.song = song
    }

    private var playlist: [MusicItem] {
        if !viewModel.currentQueue.isEmpty {
            return viewModel.currentQueue
        }

        return viewModel.savedSongs
    }

    private var activeSong: MusicItem? {
        if let currentSong = viewModel.currentSong {
            return currentSong
        }

        if playlist.indices.contains(currentIndex) {
            return playlist[currentIndex]
        }

        return song
    }

    private var playbackDuration: Double {
        max(playbackController.duration, 1)
    }

    private var sliderValue: Binding<Double> {
        Binding(
            get: {
                isDraggingSlider ? pendingSeekTime : playbackController.currentTime
            },
            set: { newValue in
                pendingSeekTime = newValue
            }
        )
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                topBar
                artworkView
                songDetails
                playbackControls
                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            syncCurrentSong()
        }
        .onChange(of: viewModel.currentSong?.id) { _, _ in
            syncIndexToCurrentSong()
            prepareActiveSong(autoplay: isPlaying)
        }
        .onChange(of: viewModel.currentQueue.map(\.id)) { _, _ in
            syncCurrentSong()
        }
        .onChange(of: viewModel.savedSongs.map(\.id)) { _, _ in
            syncCurrentSong()
        }
        .onChange(of: playbackController.didFinishPlayback) { _, didFinish in
            guard didFinish else { return }
            handleTrackCompletion()
        }
        .onReceive(playbackTimer) { _ in
            playbackController.refreshProgress()
        }
        .onDisappear {
            playbackController.pause()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                viewModel.dismissPlayback()
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                if let activeSong {
                    viewModel.addSong(activeSong)
                }
            } label: {
                Image(systemName: isSongSaved ? "checkmark" : "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private var artworkView: some View {
        Group {
            if let coverURL = activeSong?.coverURL,
               let url = URL(string: coverURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    artworkPlaceholder
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(width: 260, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(AppColors.accent.opacity(0.55))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 72))
                    .foregroundColor(.white.opacity(0.8))
            }
    }

    private var songDetails: some View {
        VStack(spacing: 8) {
            Text(activeSong?.title ?? "No Song Selected")
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(activeSong?.artist ?? "")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))

            if let album = activeSong?.album, !album.isEmpty {
                Text(album)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Text(queueSummaryText)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.65))

            if activeSong == nil {
                Text("Add songs to MyList to browse them here.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 4)
            } else if playbackController.duration == 0 {
                Text("Audio file unavailable for this song.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 4)
            }
        }
    }

    private var playbackControls: some View {
        VStack(spacing: 16) {
            Slider(
                value: sliderValue,
                in: 0...playbackDuration,
                onEditingChanged: { isEditing in
                    isDraggingSlider = isEditing

                    if isEditing {
                        pendingSeekTime = playbackController.currentTime
                    } else {
                        playbackController.seek(to: pendingSeekTime)
                    }
                }
            )
            .tint(.white)
            .disabled(activeSong == nil || playbackController.duration == 0)

            HStack {
                Text(formattedTime(isDraggingSlider ? pendingSeekTime : playbackController.currentTime))
                Spacer()
                Text(formattedTime(playbackController.duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundColor(.white.opacity(0.8))

            HStack(spacing: 28) {
                Button {
                    isRepeatEnabled.toggle()
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isRepeatEnabled ? AppColors.accent : .white)
                }

                Button {
                    skipBackward()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                .disabled(!hasPreviousSong && playbackController.currentTime <= 0)

                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: playbackController.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(AppColors.background)
                        .frame(width: 82, height: 82)
                        .background(.white)
                        .clipShape(Circle())
                }

                Button {
                    skipForward()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                .disabled(!hasNextSong)

                Button {
                    shuffleToRandomSong()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .disabled(playlist.count < 2)
            }
            .disabled(activeSong == nil || playbackController.duration == 0)
        }
    }

    private var hasNextSong: Bool {
        currentIndex < playlist.count - 1
    }

    private var hasPreviousSong: Bool {
        currentIndex > 0
    }

    private var isSongSaved: Bool {
        guard let activeSong else { return false }
        return viewModel.isSaved(activeSong)
    }

    private var queueSummaryText: String {
        guard activeSong != nil else {
            return "No active queue"
        }

        if playlist.count <= 1 {
            return isSongSaved ? "Saved in MyList" : "Single song queue"
        }

        let position = min(currentIndex + 1, playlist.count)
        return "Track \(position) of \(playlist.count)"
    }

    private func syncCurrentSong() {
        if let currentSong = viewModel.currentSong,
           let index = playlist.firstIndex(where: { $0.id == currentSong.id }) {
            currentIndex = index
        } else if let song,
                  let index = playlist.firstIndex(where: { $0.id == song.id }) {
            currentIndex = index
            viewModel.selectPlaybackSong(song)
        } else if let firstSong = playlist.first {
            currentIndex = 0
            viewModel.selectPlaybackSong(firstSong)
        } else {
            currentIndex = 0
        }

        if activeSong == nil {
            isPlaying = false
            pendingSeekTime = 0
            playbackController.stop()
            return
        }

        prepareActiveSong(autoplay: isPlaying)
    }

    private func syncIndexToCurrentSong() {
        guard let currentSong = viewModel.currentSong,
              let index = playlist.firstIndex(where: { $0.id == currentSong.id }) else {
            return
        }

        currentIndex = index
    }

    private func togglePlayback() {
        guard activeSong != nil else { return }

        if playbackController.isPlaying {
            isPlaying = false
            playbackController.pause()
        } else {
            isPlaying = true
            prepareActiveSong(autoplay: true)
        }
    }

    private func handleTrackCompletion() {
        if isRepeatEnabled {
            playbackController.seek(to: 0)
            playbackController.play()
        } else if hasNextSong {
            selectSong(at: currentIndex + 1)
        } else {
            isPlaying = false
            playbackController.seek(to: playbackController.duration)
        }
    }

    private func skipBackward() {
        guard activeSong != nil else { return }

        if playbackController.currentTime > 3 {
            playbackController.seek(to: 0)
            return
        }

        if hasPreviousSong {
            selectSong(at: currentIndex - 1)
        } else {
            playbackController.seek(to: 0)
        }
    }

    private func skipForward() {
        guard hasNextSong else { return }
        selectSong(at: currentIndex + 1)
    }

    private func shuffleToRandomSong() {
        guard playlist.count > 1 else { return }

        var nextIndex = Int.random(in: 0..<playlist.count)
        while nextIndex == currentIndex {
            nextIndex = Int.random(in: 0..<playlist.count)
        }

        selectSong(at: nextIndex)
    }

    private func selectSong(at index: Int) {
        guard playlist.indices.contains(index) else { return }
        currentIndex = index
        viewModel.selectPlaybackSong(playlist[index])
        prepareActiveSong(autoplay: isPlaying)
    }

    private func prepareActiveSong(autoplay: Bool) {
        guard let activeSong else { return }

        playbackController.prepare(song: activeSong)
        pendingSeekTime = playbackController.currentTime

        if autoplay {
            playbackController.play()
        } else {
            playbackController.pause()
        }
    }

    private func formattedTime(_ time: Double) -> String {
        guard time.isFinite, time > 0 else {
            return "0:00"
        }

        let totalSeconds = Int(time.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    PlaybackView()
        .environmentObject(MusicViewModel())
}
