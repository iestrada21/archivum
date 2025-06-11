import Foundation
import ZIPFoundation // For unzipping EPUBs
import SwiftSoup    // For parsing HTML content from EPUBs
// GRDB is not used directly in this file.

// NOTE: The definitions for CodexDocument, Chapter, and Verse
// should be in your Models/CodexDocument.swift file, NOT here.
// Make sure they are marked as Sendable in that file:
// struct CodexDocument: Identifiable, Codable, Sendable { ... }
// struct Chapter: Codable, Equatable, Sendable { ... }
// struct Verse: Codable, Equatable, Sendable { ... }


// Helper struct to encapsulate parsing logic that can be run non-isolated
struct CodexParsingLogic: Sendable {
    let commonChapterMarkers: [String]
    let sentenceTerminators: CharacterSet

    // REMOVED: private let fileManager = FileManager.default
    // FileManager.default will be used directly in methods.

    nonisolated func extractTextFromEpub(epubURL: URL) -> String? {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) // USE FileManager.default
        var fullTextContent = ""
        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil) // USE FileManager.default
            try FileManager.default.unzipItem(at: epubURL, to: tempDirectory) // USE FileManager.default
            let containerXMLPath = tempDirectory.appendingPathComponent("META-INF/container.xml")
            guard FileManager.default.fileExists(atPath: containerXMLPath.path) else { // USE FileManager.default
                print("Error: META-INF/container.xml not found in EPUB.")
                throw NSError(domain: "EpubParse", code: 301, userInfo: [NSLocalizedDescriptionKey: "META-INF/container.xml not found."])
            }
            let containerData = try Data(contentsOf: containerXMLPath)
            let opfPath = try parseContainerXML(xmlData: containerData)
            let opfFullPath = tempDirectory.appendingPathComponent(opfPath)
            guard FileManager.default.fileExists(atPath: opfFullPath.path) else { // USE FileManager.default
                print("Error: OPF file not found at path: \(opfPath)")
                throw NSError(domain: "EpubParse", code: 302, userInfo: [NSLocalizedDescriptionKey: "OPF file not found at \(opfPath)."])
            }
            let opfData = try Data(contentsOf: opfFullPath)
            let (manifest, spine) = try parseOPF(xmlData: opfData, opfDirectory: opfFullPath.deletingLastPathComponent())
            for itemIDRef in spine {
                guard let manifestItemPath = manifest[itemIDRef] else { continue }
                guard FileManager.default.fileExists(atPath: manifestItemPath.path) else { continue } // USE FileManager.default
                let contentData = try Data(contentsOf: manifestItemPath)
                if let htmlString = String(data: contentData, encoding: .utf8) {
                    let plainText = try SwiftSoup.parse(htmlString).text()
                    fullTextContent += plainText + "\n\n"
                }
            }
        } catch {
            print("Error during EPUB processing: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: tempDirectory) // USE FileManager.default
            return nil
        }
        try? FileManager.default.removeItem(at: tempDirectory) // USE FileManager.default
        return fullTextContent.isEmpty ? nil : fullTextContent
    }

    nonisolated private func parseContainerXML(xmlData: Data) throws -> String {
        guard let xmlString = String(data: xmlData, encoding: .utf8) else {
            throw NSError(domain: "EpubParse", code: 303, userInfo: [NSLocalizedDescriptionKey: "Could not decode container.xml."])
        }
        if let rangeFrom = xmlString.range(of: "full-path=\""),
           let rangeTo = xmlString.range(of: "\"", options: [], range: rangeFrom.upperBound..<xmlString.endIndex) {
            return String(xmlString[rangeFrom.upperBound..<rangeTo.lowerBound])
        }
        throw NSError(domain: "EpubParse", code: 304, userInfo: [NSLocalizedDescriptionKey: "Could not find 'full-path' attribute."])
    }

    nonisolated private func parseOPF(xmlData: Data, opfDirectory: URL) throws -> (manifest: [String: URL], spine: [String]) {
        guard let opfContents = String(data: xmlData, encoding: .utf8) else {
             throw NSError(domain: "EpubParse", code: 305, userInfo: [NSLocalizedDescriptionKey: "Could not decode OPF file."])
        }
        var manifestItems = [String: URL]()
        var spineItems = [String]()
        // Using try! for NSRegularExpression assuming patterns are valid and tested.
        let manifestRegex = try! NSRegularExpression(pattern: "<item[^>]*id=\"([^\"]+)\"[^>]*href=\"([^\"]+)\"[^>]*media-type=\"application/xhtml\\+xml\"[^>]*>", options: .caseInsensitive)
        let manifestMatches = manifestRegex.matches(in: opfContents, options: [], range: NSRange(opfContents.startIndex..., in: opfContents))
        for match in manifestMatches {
            if match.numberOfRanges == 3 {
                let id = (opfContents as NSString).substring(with: match.range(at: 1))
                let href = (opfContents as NSString).substring(with: match.range(at: 2))
                manifestItems[id] = opfDirectory.appendingPathComponent(href).standardizedFileURL
            }
        }
        let spineContentRegexPattern = "<spine[^>]*>(.*?)</spine>"
        let spineElementRegex = try! NSRegularExpression(pattern: spineContentRegexPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        if let spineMatch = spineElementRegex.firstMatch(in: opfContents, options: [], range: NSRange(opfContents.startIndex..., in: opfContents)) {
            if spineMatch.numberOfRanges > 1, let spineContentRange = Range(spineMatch.range(at: 1), in: opfContents) {
                let spineContent = String(opfContents[spineContentRange])
                let itemrefRegex = try! NSRegularExpression(pattern: "<itemref[^>]*idref=\"([^\"]+)\"[^>]*>", options: .caseInsensitive)
                let itemrefMatches = itemrefRegex.matches(in: spineContent, options: [], range: NSRange(spineContent.startIndex..., in: spineContent))
                for match in itemrefMatches {
                    if match.numberOfRanges == 2 { spineItems.append((spineContent as NSString).substring(with: match.range(at: 1))) }
                }
            }
        }
        return (manifestItems, spineItems)
    }

    nonisolated func extractChapterTitle(from line: String) -> String? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        for marker in commonChapterMarkers {
            if trimmedLine.uppercased().hasPrefix(marker.uppercased()) {
                var title = String(trimmedLine.dropFirst(marker.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                if Int(title) != nil && !marker.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().contains("chapter") {
                    if !marker.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasSuffix("chapter") { title = "Chapter \(title)" }
                } else if title.isEmpty { title = "Unnamed Chapter" }
                return title
            }
        }
        return nil
    }

    nonisolated func parseContentIntoChapters(_ content: String, originalFileName: String, isMigration: Bool = false) -> [Chapter] {
        var chapters: [Chapter] = []
        let lines = content.components(separatedBy: .newlines)
        var currentChapterLines: [String] = []
        var currentChapterNumber = 0
        var potentialChapterTitle: String? // Variable to store title from extractChapterTitle
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if let extractedTitle = extractChapterTitle(from: trimmedLine) { // Store the extracted title
                if !currentChapterLines.isEmpty {
                    currentChapterNumber += 1
                    let verses = parseSentencesIntoVerses(currentChapterLines.joined(separator: "\n"), chapterNumber: currentChapterNumber)
                    if !verses.isEmpty { chapters.append(Chapter(number: currentChapterNumber, verses: verses)) }
                }
                currentChapterLines = []
                potentialChapterTitle = extractedTitle // Assign the used title to potentialChapterTitle
            } else if !trimmedLine.isEmpty {
                currentChapterLines.append(trimmedLine)
            }
        }
        if !currentChapterLines.isEmpty {
            currentChapterNumber += 1
            let verses = parseSentencesIntoVerses(currentChapterLines.joined(separator: "\n"), chapterNumber: currentChapterNumber)
            if !verses.isEmpty { chapters.append(Chapter(number: currentChapterNumber, verses: verses)) }
        } else if potentialChapterTitle != nil && chapters.isEmpty && currentChapterNumber == 0 { // Check against potentialChapterTitle
            currentChapterNumber += 1
            chapters.append(Chapter(number: currentChapterNumber, verses: []))
        }
        if chapters.isEmpty && !isMigration && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let verses = parseSentencesIntoVerses(content, chapterNumber: 1)
            if !verses.isEmpty { chapters.append(Chapter(number: 1, verses: verses)) }
        }
        return chapters
    }

    nonisolated private func parseSentencesIntoVerses(_ chapterContent: String, chapterNumber: Int) -> [Verse] {
        var verses: [Verse] = []
        var verseNumber = 1
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = chapterContent
        let range = NSRange(location: 0, length: chapterContent.utf16.count)
        tagger.enumerateTags(in: range, unit: .sentence, scheme: .tokenType, options: []) { _, tokenRange, _ in
            let sentence = (chapterContent as NSString).substring(with: tokenRange).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                var verseText = sentence
                var parsedVerseNumber: Int?
                let regex = try! NSRegularExpression(pattern: #"^\s*(\[(\d+)\]\s*|(\d+)\.\s*)"#)
                if let match = regex.firstMatch(in: sentence, options: [], range: NSRange(sentence.startIndex..., in: sentence)) {
                    if let numRange = Range(match.range(at: 2), in: sentence) ?? Range(match.range(at: 3), in: sentence) {
                        parsedVerseNumber = Int(String(sentence[numRange]))
                        verseText = String(sentence.dropFirst(match.range(at: 0).length)).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                if !verseText.isEmpty {
                    verses.append(Verse(number: parsedVerseNumber ?? verseNumber, text: verseText))
                    verseNumber = (parsedVerseNumber ?? verseNumber) + 1
                }
            }
        }
        return verses
    }
}


@MainActor
class CodexManager: ObservableObject {
    @Published var documents: [CodexDocument] = []

    private let fileManager = FileManager.default // This is fine here, as CodexManager methods are @MainActor
    private let documentsDirectory: URL
    private let parsingLogic: CodexParsingLogic

    init() {
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let commonMarkers = [
            "#CHAPTER", "##CHAPTER", "CHAPTER ",
            "# Chapter", "## Chapter", "Chapter "
        ]
        let sentenceTerms = CharacterSet(charactersIn: ".?!")
        self.parsingLogic = CodexParsingLogic(commonChapterMarkers: commonMarkers, sentenceTerminators: sentenceTerms)
        print("Documents directory (CodexManager): \(documentsDirectory.path)")
        loadDocuments()
    }

    func importDocument(from url: URL, title: String, completion: @Sendable @escaping (Bool, String?) -> Void) {
        let sendableURL = url
        let sendableTitle = title
        let localParsingLogic = self.parsingLogic
        let localDocumentsDirectory = self.documentsDirectory

        Task.detached(priority: .background) {
            var success = false
            var errorMessage: String?
            var importedDocumentData: CodexDocument?

            do {
                let data = try Data(contentsOf: sendableURL)
                let finalTitle = sendableTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                    (sendableURL.deletingPathExtension().lastPathComponent) : sendableTitle
                
                var chapters: [Chapter] = []
                let fileExtension = sendableURL.pathExtension.lowercased()

                if fileExtension == "epub" {
                    if let epubTextContent = localParsingLogic.extractTextFromEpub(epubURL: sendableURL) {
                        chapters = localParsingLogic.parseContentIntoChapters(epubTextContent, originalFileName: finalTitle)
                    } else {
                        throw NSError(domain: "CodexImport", code: 201, userInfo: [NSLocalizedDescriptionKey: "Failed to extract text content from EPUB: \(finalTitle)."])
                    }
                } else if fileExtension == "json" {
                    guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        throw NSError(domain: "CodexImport", code: 100, userInfo: [NSLocalizedDescriptionKey: "JSON root is not a dictionary."])
                    }
                    if let chaptersData = jsonObject["chapters"] as? [[String: Any]] {
                        chapters = chaptersData.enumerated().map { (index, chapterData) -> Chapter in
                            let number = chapterData["number"] as? Int ?? (index + 1)
                            let versesData = chapterData["verses"] as? [[String: Any]] ?? []
                            let verses = versesData.enumerated().map { (vIndex, verseData) -> Verse in
                                Verse(number: verseData["number"] as? Int ?? (vIndex + 1),
                                      text: verseData["text"] as? String ?? "")
                            }
                            return Chapter(number: number, verses: verses)
                        }
                    } else if let contentStr = jsonObject["content"] as? String {
                        chapters = localParsingLogic.parseContentIntoChapters(contentStr, originalFileName: finalTitle)
                    } else {
                        throw NSError(domain: "CodexImport", code: 101, userInfo: [NSLocalizedDescriptionKey: "JSON missing 'chapters' or 'content'."])
                    }
                } else if fileExtension == "txt" {
                    if let textContent = String(data: data, encoding: .utf8) {
                        chapters = localParsingLogic.parseContentIntoChapters(textContent, originalFileName: finalTitle)
                    } else {
                        throw NSError(domain: "CodexImport", code: 102, userInfo: [NSLocalizedDescriptionKey: "Failed to decode TXT file."])
                    }
                } else {
                     if let textContent = String(data: data, encoding: .utf8) {
                        chapters = localParsingLogic.parseContentIntoChapters(textContent, originalFileName: finalTitle)
                    } else {
                        throw NSError(domain: "CodexImport", code: 104, userInfo: [NSLocalizedDescriptionKey: "File type '\(fileExtension)' not recognized/decoded."])
                    }
                }
                
                if chapters.isEmpty && fileExtension != "epub" {
                     print("Warning: No chapters parsed for non-EPUB file '\(finalTitle)'.")
                }

                importedDocumentData = CodexDocument(id: UUID(), title: finalTitle, chapters: chapters)
                // Use localDocumentsDirectory captured by the Task
                let documentURL = localDocumentsDirectory.appendingPathComponent("\(importedDocumentData!.id).json")
                let encodedData = try JSONEncoder().encode(importedDocumentData!)
                try encodedData.write(to: documentURL)
                success = true
            } catch let anError as NSError {
                errorMessage = anError.localizedDescription
            } catch {
                errorMessage = "Failed to inscribe document '\(sendableTitle)': \(error.localizedDescription)."
            }

            await MainActor.run {
                if success, let doc = importedDocumentData {
                    self.documents.append(doc)
                }
                completion(success, errorMessage)
            }
        }
    }
    
    func getDocument(id: UUID) -> CodexDocument? {
        return documents.first { $0.id == id }
    }

    func deleteDocument(id: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let documentToDelete = documents[index]
        documents.remove(at: index)

        let docIdToDelete = documentToDelete.id
        let localDocumentsDirectory = self.documentsDirectory
        // fileManager is accessible on MainActor self, but for consistency in background task:
        // let localFileManager = FileManager.default // Can be used directly in detached task

        Task.detached(priority: .background) {
            let documentURL = localDocumentsDirectory.appendingPathComponent("\(docIdToDelete).json")
            do {
                try FileManager.default.removeItem(at: documentURL) // Use FileManager.default directly
                print("Deleted document file from disk: \(docIdToDelete)")
            } catch {
                print("Failed to delete document file \(docIdToDelete) from disk: \(error.localizedDescription)")
            }
        }
    }

    func renameDocument(id: UUID, newTitle: String) {
        guard let index = documents.firstIndex(where: { $0.id == id }), !newTitle.isEmpty else { return }
        
        var docToUpdate = self.documents[index]
        docToUpdate.title = newTitle
        self.documents[index] = docToUpdate

        let updatedDocumentData = docToUpdate
        let localDocumentsDirectory = self.documentsDirectory

        Task.detached(priority: .background) {
            let documentURL = localDocumentsDirectory.appendingPathComponent("\(updatedDocumentData.id).json")
            do {
                let encodedData = try JSONEncoder().encode(updatedDocumentData)
                try encodedData.write(to: documentURL)
                print("Saved renamed document to disk: \(updatedDocumentData.title)")
            } catch {
                print("Failed to save renamed document \(updatedDocumentData.title) to disk: \(error.localizedDescription)")
            }
        }
    }

    private func loadDocuments() {
        let localDocumentsDirectory = self.documentsDirectory
        let localParsingLogic = self.parsingLogic
        // let localFileManager = FileManager.default // Can be used directly in detached task

        Task.detached(priority: .background) {
            var loadedDocsFromDisk: [CodexDocument] = []
            do {
                let documentURLs = try FileManager.default.contentsOfDirectory( // Use FileManager.default directly
                    at: localDocumentsDirectory,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                ).filter { $0.pathExtension == "json" }
                
                loadedDocsFromDisk = documentURLs.compactMap { url -> CodexDocument? in
                    do {
                        let data = try Data(contentsOf: url)
                        if let document = try? JSONDecoder().decode(CodexDocument.self, from: data) {
                            return document
                        }
                        struct OldCodexDocument: Codable { let id: UUID; let title: String; let sentences: [String] }
                        let oldDocument = try JSONDecoder().decode(OldCodexDocument.self, from: data)
                        let singleChapterContent = oldDocument.sentences.joined(separator: "\n")
                        
                        let migratedChapters = localParsingLogic.parseContentIntoChapters(singleChapterContent, originalFileName: url.lastPathComponent, isMigration: true)
                        let newDocument = CodexDocument(id: oldDocument.id, title: oldDocument.title, chapters: migratedChapters)
                        
                        let newDocURL = localDocumentsDirectory.appendingPathComponent("\(newDocument.id).json")
                        try JSONEncoder().encode(newDocument).write(to: newDocURL)
                        return newDocument
                    } catch {
                        print("Failed to load or migrate document at \(url): \(error.localizedDescription)")
                        return nil
                    }
                }
            } catch {
                print("Failed to list documents in directory: \(error.localizedDescription)")
            }

            await MainActor.run {
                self.documents = loadedDocsFromDisk
            }
        }
    }
}
