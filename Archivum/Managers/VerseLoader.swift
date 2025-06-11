// In VerseLoader.swift

import Foundation

class VerseLoader {
    enum BibleVersion: String {
        case kjv = "kjv"
        // Future versions: case esv = "esv", nasb = "nasb"
    }

    private var verses: [BibleVersion: [String: String]] = [:]

    init() {
        if let kjvVerses = loadVerses(for: .kjv) {
            verses[.kjv] = kjvVerses
        }
    }

    func loadVerses(for version: BibleVersion) -> [String: String]? {
        guard let url = Bundle.main.url(forResource: "\(version.rawValue)verses", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            print("Failed to load \(version.rawValue)verses.json")
            return nil
        }
        return json
    }

    func getVerses(for version: BibleVersion) -> [String: String] {
        if verses[version] == nil, let loadedVerses = loadVerses(for: version) {
            verses[version] = loadedVerses
        }
        return verses[version] ?? [:]
    }

    func getVersesForChapter(book: String, chapter: Int, version: BibleVersion) -> [BibleVerse] {
        let versionVerses = getVerses(for: version)
        return versionVerses
            .filter { $0.key.hasPrefix("\(book) \(chapter):") }
            .map { (key, value) in
                let components = key.split(separator: ":")
                let verseNum = Int(components.last ?? "0") ?? 0
                return BibleVerse(reference: key, book: book, chapter: chapter, verse: verseNum, text: value)
            }
            .sorted { $0.verse < $1.verse }
    }

    // MODIFIED: Added bookAbbreviations parameter
    func searchVerses(query: String, version: BibleVersion, bookAbbreviations: [String: String]) -> [(reference: String, book: String, chapterVerse: String, text: String)] {
        let versionVerses = getVerses(for: version)
        let lowercasedQuery = query.lowercased()
        return versionVerses
            .filter { $0.value.lowercased().contains(lowercasedQuery) }
            .map { (reference, text) in
                let components = reference.split(separator: " ")
                var bookParts: [String] = []
                var chapterVerse: String = ""
                for component in components {
                    if component.contains(":") {
                        chapterVerse = String(component)
                        break
                    }
                    bookParts.append(String(component))
                }
                let book = bookParts.joined(separator: " ")
                // Use the passed-in bookAbbreviations
                let abbreviatedBook = bookAbbreviations[book] ?? book
                return (
                    reference: reference,
                    book: abbreviatedBook,
                    chapterVerse: chapterVerse,
                    text: text
                )
            }
            .sorted { $0.reference < $1.reference }
    }
}
