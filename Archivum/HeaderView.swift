//
//  HeaderView.swift
//  Archivum
//
//  Created by Ivan Estrada on 4/26/25.
//
import SwiftUI

struct HeaderView: View {
    @Binding var activeTab: String
    @Binding var navigationState: ContentView.NavigationState

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.green, lineWidth: 1)
                .frame(height: 44)
            HStack(spacing: 0) {
                Text("Archivum")
                    .font(.custom("IBM Plex Mono", size: 18))
                    .foregroundColor(.green)
                    .padding(.leading, 5)
                    .frame(height: 44)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(["SCRIPTURE", "NOTES", "DATA", "SEARCH", "SETTINGS"], id: \.self) { tab in
                            HStack(spacing: 0) {
                                Text(tab)
                                    .font(.custom("IBM Plex Mono", size: 14))
                                    .foregroundColor(activeTab == tab ? .black : .green)
                                    .background(activeTab == tab ? Color.green : Color.black)
                                    .padding(.horizontal, 5)
                                    .onTapGesture {
                                        activeTab = tab
                                        if tab == "SCRIPTURE" && navigationState != .verses {
                                            navigationState = .verses
                                        }
                                    }
                                if tab != "SETTINGS" {
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: 1, height: 20)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                    .frame(height: 44)
                }
                .padding(.leading, 70)
            }
        }
        .background(Color.black)
    }
}
