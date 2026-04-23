//
//  SearchView.swift
//  
//
//  Created by csuftitan on 4/23/26.
//

import SwiftUI


struct SearchView: View {
    
    let sampleMusic = [
        MusicItem(title: "Blinding Lights", artist: "The Weeknd"),
        MusicItem(title: "SICKO MODE", artist: "Travis Scott"),
        MusicItem(title: "Levitating", artist: "Dua Lipa")
    ]
    
    var body: some View {
        List(sampleMusic) { music in
            VStack(alignment: .leading) {
                Text(music.title)
                    .font(.headline)
                Text(music.artist)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Search")
    }
}

#Preview {
    SearchView()
}
