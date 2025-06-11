import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @Binding var searchQuery: String
    @Binding var searchType: SearchType
    @Binding var scriptureScope: ScriptureSearchScope
    @Binding var showScopeOptions: Bool

    enum SearchType {
        case scripture
        case codex
    }

    enum ScriptureSearchScope {
        case all
        case byProfile
        case byBook
    }

    private let books = [
        "All Books",
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
                if showScopeOptions {
                    if searchType == .scripture {
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
                                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    notesManager.selectedBook = book
                                    scriptureScope = (book == "All Books") ? .all : .byBook
                                    showScopeOptions = false
                                }
                        }
                    } else {
                        ForEach(notesManager.codexManager.documents, id: \.id) { document in
                            Text(document.title)
                                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(themeManager.backgroundColor)
                                .overlay(
                                    Rectangle()
                                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    notesManager.selectedCodexDocumentId = document.id
                                    showScopeOptions = false
                                }
                        }
                    }
                } else {
                    if searchQuery.count >= 3 {
                        switch searchType {
                        case .scripture:
                            let filteredVerses = filterVerses()
                            if filteredVerses.isEmpty {
                                Text("No Results")
                                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                            } else {
                                ForEach(filteredVerses, id: \.reference) { verse in
                                    HStack(alignment: .top, spacing: 10) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(verse.book)
                                                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                            Text(verse.chapterVerse)
                                                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                                                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                        }
                                        .frame(width: 60, alignment: .leading)

                                        Text(verse.text)
                                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .overlay(
                                        Rectangle()
                                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                                    )
                                }
                            }

                        case .codex:
                            let filteredVerses = filterCodexVerses()
                            if filteredVerses.isEmpty {
                                Text("No Results")
                                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                            } else {
                                ForEach(filteredVerses, id: \.reference) { verse in
                                    HStack(alignment: .top, spacing: 10) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(verse.documentTitle)
                                                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                            Text("Chapter \(verse.chapterNumber), Verse \(verse.verseNumber)")
                                                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                                                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                        }
                                        .frame(width: 100, alignment: .leading)

                                        Text(verse.text)
                                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .overlay(
                                        Rectangle()
                                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                                    )
                                }
                            }
                        }
                    } else if !searchQuery.isEmpty {
                        Text("Enter at least 3 characters to search")
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 15)
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .background(themeManager.backgroundColor)
    }

    private func filterVerses() -> [(reference: String, book: String, chapterVerse: String, text: String)] {
        var filtered = notesManager.searchVerses(query: searchQuery)
        switch scriptureScope {
        case .all:
            break
        case .byProfile:
            guard let profile = notesManager.selectedProfile, profile.nodeType == .scripture else { return [] }
            let verseRefsWithNotes = Set(profile.notes.keys)
            filtered = filtered.filter { verseRefsWithNotes.contains($0.reference) }
        case .byBook:
            guard notesManager.selectedBook != "All Books" else { return filtered }
            filtered = filtered.filter { $0.reference.hasPrefix(notesManager.selectedBook) }
        }
        return filtered
    }

    private func filterCodexVerses() -> [(reference: String, documentTitle: String, chapterNumber: Int, verseNumber: Int, text: String)] {
        guard let documentId = notesManager.selectedCodexDocumentId,
              let document = notesManager.codexManager.getDocument(id: documentId) else { return [] }
        let lowercasedQuery = searchQuery.lowercased()
        var results: [(reference: String, documentTitle: String, chapterNumber: Int, verseNumber: Int, text: String)] = []

        for chapter in document.chapters {
            let filteredVerses = chapter.verses.enumerated().filter { $0.element.text.lowercased().contains(lowercasedQuery) }
            results.append(contentsOf: filteredVerses.map { (index, verse) in
                (
                    reference: "\(document.id)_\(chapter.number):\(verse.number)",
                    documentTitle: document.title,
                    chapterNumber: chapter.number,
                    verseNumber: verse.number,
                    text: verse.text
                )
            })
        }

        return results
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            notesManager: NotesManager(),
            searchQuery: .constant(""),
            searchType: .constant(.scripture),
            scriptureScope: .constant(.all),
            showScopeOptions: .constant(false)
        )
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
    }
}
