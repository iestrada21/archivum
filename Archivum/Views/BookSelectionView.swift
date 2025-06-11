//
//  BookSelectionView.swift
//  Archivum
//
//  Created by Ivan Estrada on 5/2/25.
//

import SwiftUI

struct BookSelectionView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @Binding var selectedBook: String
    let showAllBooks: Bool // New parameter to control "All Books" visibility
    let isEnabled: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private let books = [
        "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth",
        "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
        "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon",
        "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
        "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah",
        "Malachi", "Matthew", "Mark", "Luke", "John", "Acts", "Romans", "1 Corinthians",
        "2 Corinthians", "Galatians", "Ephesians", "Philippians", "Colossians", "1 Thessalonians",
        "2 Thessalonians", "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James",
        "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Select Book")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)

                if showAllBooks {
                    Text("All Books")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeManager.backgroundColor)
                        .overlay(
                            Rectangle()
                                .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isEnabled {
                                selectedBook = "All Books"
                                onConfirm()
                            }
                        }
                        .opacity(isEnabled ? 1.0 : 0.5)
                }

                ForEach(books, id: \.self) { book in
                    Text(book)
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeManager.backgroundColor)
                        .overlay(
                            Rectangle()
                                .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isEnabled {
                                selectedBook = book
                                onConfirm()
                            }
                        }
                        .opacity(isEnabled ? 1.0 : 0.5)
                }

                HStack(spacing: 10) {
                    Button("[Annul Task]") {
                        onCancel()
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 140, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                    )
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
            }
            .padding(10)
        }
        .background(themeManager.backgroundColor)
    }
}
