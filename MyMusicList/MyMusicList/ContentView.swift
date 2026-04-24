//
//  ContentView.swift
//  MyMusicList
//
//  Created by csuftitan on 4/23/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Text("MyMusicList 🎵")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Track your favorite songs and albums")
                    .foregroundColor(.gray)
                
                NavigationLink(destination: SearchView()) {
                    Text("Search Music")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: MyListView()) {
                    Text("My List")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
