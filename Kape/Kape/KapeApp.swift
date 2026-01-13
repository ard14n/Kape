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
