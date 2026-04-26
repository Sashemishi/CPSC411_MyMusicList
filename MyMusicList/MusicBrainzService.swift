//
//  MusicBrainzService.swift
//  MyMusicList
//
//  Created by csuftitan on 4/26/26.
//
import Foundation

struct MusicBrainzRecording: Codable {
    let id: String
    let title: String
    let artistCredit: [ArtistCredit]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artistCredit = "artist-credit"
    }
}

struct ArtistCredit: Codable {
    let name: String
}


class MusicBrainzService {
    func searchSongs(query: String) async throws -> [MusicItem] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        let url = URL(string:
            "https://musicbrainz.org/ws/2/recording?query=\(encodedQuery)&fmt=json"
        )!

        var request = URLRequest(url: url)
        request.setValue("MyMusicList/1.0 (your-email@example.com)", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)

        let response = try JSONDecoder().decode(MusicBrainzResponse.self, from: data)

        return response.recordings.map {
            MusicItem(
                title: $0.title,
                artist: $0.artistCredit?.first?.name ?? "Unknown Artist"
            )
        }
    }
}

struct MusicBrainzResponse: Codable {
    let recordings: [MusicBrainzRecording]
}
