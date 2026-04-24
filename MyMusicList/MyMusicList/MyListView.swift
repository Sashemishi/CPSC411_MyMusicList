//
//  MyListView.swift
//  
//
//  Created by csuftitan on 4/23/26.
//

import SwiftUI

struct MyListView: View {
    @EnvironmentObject var viewModel: MusicViewModel

    var body: some View {
        List {
            if viewModel.savedSongs.isEmpty {
                Text("No songs added yet.")
                    .foregroundColor(.gray)
            } else {
                ForEach(viewModel.savedSongs) { music in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(music.title)
                            .font(.headline)

                        Text(music.artist)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("My List")
    }
}

#Preview {
    MyListView()
        .environmentObject(MusicViewModel())
}
