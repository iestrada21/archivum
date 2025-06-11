//
//  SubheaderView.swift
//  Archivum
//
//  Created by Ivan Estrada on 4/26/25.
//

import SwiftUI

struct SubheaderView: View {
    @ObservedObject var notesManager: NotesManager
    @Binding var navigationState: ContentView.NavigationState

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.green, lineWidth: 1)
                .frame(height: 44)
            HStack {
                Button(notesManager.selectedBook) {
                    navigationState = .bookSelection
                }
                .font(.custom("IBM Plex Mono", size: 12))
                .foregroundColor(.green)
                .frame(width: 140, height: 30)
                .overlay(Rectangle().stroke(Color.green, lineWidth: 1))
                Spacer()
                Button(String(notesManager.selectedChapter)) {
                    navigationState = .chapterSelection
                }
                .font(.custom("IBM Plex Mono", size: 12))
                .foregroundColor(.green)
                .frame(width: 30, height: 30)
                .overlay(Rectangle().stroke(Color.green, lineWidth: 1))
                .monospacedDigit()
                Spacer()
                Text("PROFILE: \(notesManager.selectedProfile?.name ?? "None")")
                    .font(.custom("IBM Plex Mono", size: 12))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 10)
            .frame(height: 44)
        }
        .background(Color.black)
    }
}
