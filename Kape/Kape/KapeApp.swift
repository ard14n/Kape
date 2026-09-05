//
//  KapeApp.swift
//  Kape
//
//  Created by Ardian Jahja on 09.01.26.
//

import SwiftUI
import SwiftData

@main
struct KapeApp: App {
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--kape-ui-tests")
            && !ProcessInfo.processInfo.arguments.contains("--kape-keep-state") {
            CharadesArchive.clear()
            UserDefaults.standard.removeObject(forKey: "kape.appearance")
            UserDefaults.standard.removeObject(forKey: "kape.sound")
            UserDefaults.standard.removeObject(forKey: "kape.play-style")
            UserDefaults.standard.set(!ProcessInfo.processInfo.arguments.contains("--kape-show-intro"), forKey: "kape.intro.play-styles.seen")
        }
        #endif
    }
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// Shared DeckService instance for the entire app
    @StateObject private var deckService = DeckService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deckService)
        }
    }
}
