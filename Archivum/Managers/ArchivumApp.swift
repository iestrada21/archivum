//
//  ArchivumApp.swift
//  Archivum
//
//  Created by Ivan Estrada on 4/26/25.
//

import SwiftUI

@main
struct ArchivumApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ThemeManager())
                .environmentObject(NotesManager())
        }
    }
}
