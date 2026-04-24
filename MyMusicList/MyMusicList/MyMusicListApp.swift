//
//  MyMusicListApp.swift
//  MyMusicList
//
//  Created by csuftitan on 4/23/26.
//

import SwiftUI

@main
struct MyMusicListApp: App {
    @StateObject var viewModel = MusicViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .envirmentObject(viewModel) 
        }
    }
}
