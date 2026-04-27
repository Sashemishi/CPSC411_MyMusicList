import SwiftUI
import Combine
import AVFoundation
import UIKit

final class PlaybackController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = PlaybackController()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var didFinishPlayback = false

    private var audioPlayer: AVAudioPlayer?
    private var currentSongID: UUID?

    func isPrepared(for song: MusicItem) -> Bool {
        currentSongID == song.id && audioPlayer != nil
    }

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

    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
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

    func embeddedArtwork(for song: MusicItem) async -> UIImage? {
        guard let url = audioURL(for: song) else { return nil }

        let asset = AVURLAsset(url: url)
        guard let metadata = try? await asset.load(.commonMetadata) else {
            return nil
        }
        let artworkItem = metadata.first {
            $0.commonKey?.rawValue == AVMetadataKey.commonKeyArtwork.rawValue
        }

        guard let artworkItem,
              let data = try? await artworkItem.load(.dataValue) else {
            return nil
        }
        return UIImage(data: data)
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
    @State private var showAddToPlaylistSheet = false
    @State private var embeddedArtwork: UIImage?
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
            loadArtwork()
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
        .sheet(isPresented: $showAddToPlaylistSheet) {
            PlaybackAddToPlaylistSheet(
                playlists: viewModel.playlists,
                onSelect: { playlist in
                    if let activeSong {
                        add(activeSong, to: playlist)
                    }
                }
            )
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

            Menu {
                if let activeSong {
                    if viewModel.playlists.isEmpty {
                        Button("No playlists yet") {}
                            .disabled(true)
                    } else {
                        ForEach(viewModel.playlists) { playlist in
                            Button(playlist.name) {
                                add(activeSong, to: playlist)
                            }
                        }
                    }

                    Divider()

                    Button("Choose…") {
                        showAddToPlaylistSheet = true
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private var artworkView: some View {
        Group {
            if let embeddedArtwork {
                Image(uiImage: embeddedArtwork)
                    .resizable()
                    .scaledToFill()
            } else if let coverURL = activeSong?.coverURL,
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
        .clipped()
        .overlay {
            Rectangle()
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var artworkPlaceholder: some View {
        Rectangle()
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
                    if isEditing {
                        isDraggingSlider = true
                        pendingSeekTime = playbackController.currentTime
                    } else {
                        let clampedTime = min(max(pendingSeekTime, 0), playbackDuration)
                        playbackController.seek(to: clampedTime)
                        pendingSeekTime = playbackController.currentTime
                        isDraggingSlider = false
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
            embeddedArtwork = nil
            playbackController.stop()
            return
        }

        guard let activeSong else { return }

        let shouldAutoplay = !playbackController.isPrepared(for: activeSong)
        isPlaying = playbackController.isPlaying || shouldAutoplay
        prepareActiveSong(autoplay: isPlaying)
        loadArtwork()
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
            pendingSeekTime = 0
            isDraggingSlider = false
            playbackController.play()
        } else if hasNextSong {
            selectSong(at: currentIndex + 1)
        } else {
            isPlaying = false
            playbackController.seek(to: playbackController.duration)
            pendingSeekTime = playbackController.currentTime
        }
    }

    private func skipBackward() {
        guard activeSong != nil else { return }

        if playbackController.currentTime > 3 {
            playbackController.seek(to: 0)
            pendingSeekTime = playbackController.currentTime
            return
        }

        if hasPreviousSong {
            selectSong(at: currentIndex - 1)
        } else {
            playbackController.seek(to: 0)
            pendingSeekTime = playbackController.currentTime
        }
    }

    private func skipForward() {
        guard hasNextSong else { return }
        selectSong(at: currentIndex + 1)
    }

    private func shuffleToRandomSong() {
        guard playlist.count > 1,
              playlist.indices.contains(currentIndex) else { return }

        let currentSong = playlist[currentIndex]
        var remainingSongs = playlist.enumerated().compactMap { index, song in
            index == currentIndex ? nil : song
        }
        remainingSongs.shuffle()

        var shuffledPlaylist = remainingSongs
        shuffledPlaylist.insert(currentSong, at: currentIndex)
        viewModel.currentQueue = shuffledPlaylist
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
        isDraggingSlider = false
        isPlaying = autoplay

        if autoplay {
            playbackController.play()
        } else {
            playbackController.pause()
        }
    }

    private func add(_ song: MusicItem, to playlist: Playlist) {
        viewModel.addSong(song, toPlaylistID: playlist.id)
        viewModel.addSong(song)
    }

    private func loadArtwork() {
        guard let activeSong else {
            embeddedArtwork = nil
            return
        }

        Task {
            let artwork = await playbackController.embeddedArtwork(for: activeSong)
            await MainActor.run {
                if self.activeSong?.id == activeSong.id {
                    embeddedArtwork = artwork
                }
            }
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

private struct PlaybackAddToPlaylistSheet: View {
    var playlists: [Playlist]
    var onSelect: (Playlist) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(playlists) { playlist in
                Button {
                    onSelect(playlist)
                    dismiss()
                } label: {
                    HStack {
                        Text(playlist.name)
                        Spacer()
                        Text("\(playlist.songs.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PlaybackView()
        .environmentObject(MusicViewModel())
}
