//
//  YTDLPDownloaderApp.swift
//  YTDLPDownloader
//
//  Created by Jeff Milner on 2025-11-05.
//

import SwiftUI

@main
struct YTDLPApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
