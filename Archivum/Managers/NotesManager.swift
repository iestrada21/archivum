import Foundation
import UniformTypeIdentifiers

@MainActor // Ensures @Published properties are updated on the main actor by default
class NotesManager: ObservableObject {
    // UI-Bound Properties
    @Published var profiles: [Profile] = []
    @Published var selectedProfile: Profile? {
        didSet {
            if oldValue?.id != selectedProfile?.id {
                Task {
                    await loadNotesForSelectedProfile()
                }
            }
        }
    }
    @Published var selectedBook: String {
        didSet { UserDefaults.standard.set(selectedBook, forKey: "selectedBook") }
    }
    @Published var selectedChapter: Int {
        didSet { UserDefaults.standard.set(selectedChapter, forKey: "selectedChapter") }
    }
    @Published var selectedCodexDocumentId: UUID? {
        didSet { UserDefaults.standard.set(selectedCodexDocumentId?.uuidString, forKey: "selectedCodexDocumentId") }
    }
    @Published var selectedCodexChapter: Int {
        didSet { UserDefaults.standard.set(selectedCodexChapter, forKey: "selectedCodexChapter") }
    }
    @Published var searchQuery: String = ""
    
    enum SortOption: CaseIterable {
        case canon, fresh, olden
    }
    @Published var sortBy: SortOption = .canon
    
    @Published var isAllNodes: Bool = false

    // ADDED enum definition for ExportScope
    enum ExportScope {
        case all, specificBook
    }

    // Managers and Loaders
    @Published var codexManager = CodexManager()
    private let verseLoader = VerseLoader()
    
    let chapterCounts: [String: Int] = [
        "Genesis": 50, "Exodus": 40, "Leviticus": 27, "Numbers": 36, "Deuteronomy": 34,
        "Joshua": 24, "Judges": 21, "Ruth": 4, "1 Samuel": 31, "2 Samuel": 24,
        "1 Kings": 22, "2 Kings": 25, "1 Chronicles": 29, "2 Chronicles": 36, "Ezra": 10,
        "Nehemiah": 13, "Esther": 10, "Job": 42, "Psalms": 150, "Proverbs": 31,
        "Ecclesiastes": 12, "Song of Solomon": 8, "Isaiah": 66, "Jeremiah": 52,
        "Lamentations": 5, "Ezekiel": 48, "Daniel": 12, "Hosea": 14, "Joel": 3,
        "Amos": 9, "Obadiah": 1, "Jonah": 4, "Micah": 7, "Nahum": 3, "Habakkuk": 3,
        "Zephaniah": 3, "Haggai": 2, "Zechariah": 14, "Malachi": 4, "Matthew": 28,
        "Mark": 16, "Luke": 24, "John": 21, "Acts": 28, "Romans": 16, "1 Corinthians": 16,
        "2 Corinthians": 13, "Galatians": 6, "Ephesians": 6, "Philippians": 4, "Colossians": 4,
        "1 Thessalonians": 5, "2 Thessalonians": 3, "1 Timothy": 6, "2 Timothy": 4, "Titus": 3,
        "Philemon": 1, "Hebrews": 13, "James": 5, "1 Peter": 5, "2 Peter": 3, "1 John": 5,
        "2 John": 1, "3 John": 1, "Jude": 1, "Revelation": 22
    ]
    static let bookAbbreviations: [String: String] = [
        "Genesis": "Gen", "Exodus": "Exod", "Leviticus": "Lev", "Numbers": "Num", "Deuteronomy": "Deut",
        "Joshua": "Josh", "Judges": "Judg", "Ruth": "Ruth", "1 Samuel": "1Sam", "2 Samuel": "2Sam",
        "1 Kings": "1Kgs", "2 Kings": "2Kgs", "1 Chronicles": "1Chr", "2 Chronicles": "2Chr", "Ezra": "Ezra",
        "Nehemiah": "Neh", "Esther": "Esth", "Job": "Job", "Psalms": "Ps", "Proverbs": "Prov",
        "Ecclesiastes": "Eccl", "Song of Solomon": "Song", "Isaiah": "Isa", "Jeremiah": "Jer",
        "Lamentations": "Lam", "Ezekiel": "Ezek", "Daniel": "Dan", "Hosea": "Hos", "Joel": "Joel",
        "Amos": "Amos", "Obadiah": "Obad", "Jonah": "Jonah", "Micah": "Mic", "Nahum": "Nah",
        "Habakkuk": "Hab", "Zephaniah": "Zeph", "Haggai": "Hag", "Zechariah": "Zech", "Malachi": "Mal",
        "Matthew": "Matt", "Mark": "Mark", "Luke": "Luke", "John": "John", "Acts": "Acts",
        "Romans": "Rom", "1 Corinthians": "1Cor", "2 Corinthians": "2Cor", "Galatians": "Gal",
        "Ephesians": "Eph", "Philippians": "Phil", "Colossians": "Col", "1 Thessalonians": "1Thess",
        "2 Thessalonians": "2Thess", "1 Timothy": "1Tim", "2 Timothy": "2Tim", "Titus": "Titus",
        "Philemon": "Phlm", "Hebrews": "Heb", "James": "Jas", "1 Peter": "1Pet", "2 Peter": "2Pet",
        "1 John": "1John", "2 John": "2John", "3 John": "3John", "Jude": "Jude", "Revelation": "Rev"
    ]

    struct NoteDisplayEntry: Identifiable, Equatable {
        let id: String
        let verseRef: String
        let note: Profile.NoteEntry
        let profileId: UUID?
        static func == (lhs: NoteDisplayEntry, rhs: NoteDisplayEntry) -> Bool {
            lhs.id == rhs.id && lhs.note.id == rhs.note.id
        }
    }

    init() {
        let initialSelectedBook = UserDefaults.standard.string(forKey: "selectedBook") ?? "Genesis"
        var initialSelectedChapterValue = UserDefaults.standard.integer(forKey: "selectedChapter")
        if initialSelectedChapterValue == 0 {
            initialSelectedChapterValue = 1
        }
        var initialSelectedCodexDocumentIdValue: UUID? = nil
        if let docIdStr = UserDefaults.standard.string(forKey: "selectedCodexDocumentId") {
            initialSelectedCodexDocumentIdValue = UUID(uuidString: docIdStr)
        }
        var initialSelectedCodexChapterValue = UserDefaults.standard.integer(forKey: "selectedCodexChapter")
        if initialSelectedCodexChapterValue == 0 {
            initialSelectedCodexChapterValue = 1
        }

        self.selectedBook = initialSelectedBook
        self.selectedChapter = initialSelectedChapterValue
        self.selectedCodexDocumentId = initialSelectedCodexDocumentIdValue
        self.selectedCodexChapter = initialSelectedCodexChapterValue
        
        Task {
            await migrateDataToDBIfNeeded()
            await loadProfilesFromDB()
        }
    }

    func toggleSortBy() {
        let allCases = SortOption.allCases
        if let currentIndex = allCases.firstIndex(of: sortBy) {
            let nextIndex = (currentIndex + 1) % allCases.count
            sortBy = allCases[nextIndex]
        } else {
            sortBy = allCases.first ?? .canon
        }
    }

    private func migrateDataToDBIfNeeded() async {
        print("Checking for data migration need...")
        if UserDefaults.standard.bool(forKey: "hasMigratedToDB_v2_ProfilesNotes") {
            print("Migration flag already set. Skipping migration check against UserDefaults.")
            return
        }
        var oldProfilesFromUserDefaults: [Profile] = []
        if let data = UserDefaults.standard.data(forKey: "profiles"),
           let savedProfiles = try? JSONDecoder().decode([Profile].self, from: data) {
            oldProfilesFromUserDefaults = savedProfiles
        }
        if !oldProfilesFromUserDefaults.isEmpty {
            print("Old profiles found in UserDefaults. Attempting migration to SQLite DB...")
            do {
                try await DatabaseManager.shared.migrateUserDefaultsToDB(profilesFromUserDefaults: oldProfilesFromUserDefaults)
                UserDefaults.standard.set(true, forKey: "hasMigratedToDB_v2_ProfilesNotes")
                print("Migration successful. Old UserDefaults 'profiles' data processed.")
            } catch {
                print("DB Migration FAILED: \(error.localizedDescription)")
            }
        } else {
            UserDefaults.standard.set(true, forKey: "hasMigratedToDB_v2_ProfilesNotes")
            print("No old 'profiles' data found in UserDefaults to migrate.")
        }
    }

    func loadProfilesFromDB() async {
        print("Loading profiles from DB...")
        do {
            let dbProfiles = try await DatabaseManager.shared.fetchProfiles()
            let appProfiles = dbProfiles.map { dbProfile in
                Profile(id: dbProfile.id, name: dbProfile.name,
                        nodeType: dbProfile.nodeType, scriptureVersion: dbProfile.scriptureVersion,
                        codexDocumentId: dbProfile.codexDocumentId, notes: [:])
            }
            self.profiles = appProfiles
            if self.selectedProfile == nil || !appProfiles.contains(where: { $0.id == self.selectedProfile?.id }) {
                self.selectedProfile = appProfiles.first
            } else if let currentSelectedId = self.selectedProfile?.id,
                      let updatedSelectedProfile = appProfiles.first(where: { $0.id == currentSelectedId}) {
                let existingNotes = self.selectedProfile?.notes ?? [:]
                self.selectedProfile = updatedSelectedProfile
                self.selectedProfile?.notes = existingNotes
            }
            if self.profiles.isEmpty {
                print("No profiles in DB. Creating default profile.")
                await self.createProfile(name: "Default", nodeType: .scripture)
            }
            self.isAllNodes = (self.selectedProfile == nil && !self.profiles.isEmpty)
            print("Profiles loaded. Count: \(self.profiles.count). Selected: \(self.selectedProfile?.name ?? "None")")
        } catch {
            print("Failed to load profiles from DB: \(error.localizedDescription)")
            if self.profiles.isEmpty {
                print("Load from DB failed, creating default profile.")
                await self.createProfile(name: "Default", nodeType: .scripture)
            }
        }
    }

    func createProfile(name: String, nodeType: Profile.NodeType, codexDocumentId: UUID? = nil) async {
        let newProfileId = UUID()
        let scriptureVersion = nodeType == .scripture ? "kjv" : nil
        let dbProfile = DBProfile(id: newProfileId, name: name, nodeType: nodeType,
                                  scriptureVersion: scriptureVersion, codexDocumentId: codexDocumentId)
        do {
            try await DatabaseManager.shared.saveProfile(dbProfile)
            let appProfile = Profile(id: newProfileId, name: name, nodeType: nodeType,
                                     scriptureVersion: scriptureVersion, codexDocumentId: codexDocumentId, notes: [:])
            self.profiles.append(appProfile)
            self.selectedProfile = appProfile
            self.isAllNodes = false
            print("Profile '\(name)' created.")
        } catch {
            print("Failed to save new profile '\(name)' to DB: \(error.localizedDescription)")
        }
    }

    func selectProfile(id: UUID) {
        guard let profileToSelect = profiles.first(where: { $0.id == id }) else {
            self.selectedProfile = nil
            self.isAllNodes = !profiles.isEmpty
            return
        }
        if selectedProfile?.id != id {
            selectedProfile = profileToSelect
            isAllNodes = false
            if profileToSelect.nodeType == .codex, let documentId = profileToSelect.codexDocumentId {
                selectedCodexDocumentId = documentId
                selectedCodexChapter = 1
            } else if profileToSelect.nodeType == .scripture {
                selectedCodexDocumentId = nil
            }
        }
    }
    
    func selectAllNodes() {
        selectedProfile = nil
        isAllNodes = true
        selectedCodexDocumentId = nil
    }

    func renameProfile(id: UUID, newName: String) async {
        guard !newName.isEmpty, let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        do {
            try await DatabaseManager.shared.updateProfileName(id: id, newName: newName)
            self.profiles[index].name = newName
            if self.selectedProfile?.id == id { self.selectedProfile = self.profiles[index] }
            print("Profile ID \(id) renamed to '\(newName)'.")
        } catch {
            print("Failed to rename profile \(id) in DB: \(error.localizedDescription)")
        }
    }

    func deleteProfile(id: UUID) async {
        do {
            try await DatabaseManager.shared.deleteProfile(id: id)
            self.profiles.removeAll { $0.id == id }
            if self.selectedProfile?.id == id {
                self.selectedProfile = self.profiles.first
            }
            if self.profiles.isEmpty {
                await self.createProfile(name: "Default", nodeType: .scripture)
            }
            self.isAllNodes = (self.selectedProfile == nil && !self.profiles.isEmpty)
            print("Profile ID \(id) deleted.")
        } catch {
            print("Failed to delete profile \(id) from DB: \(error.localizedDescription)")
        }
    }
    
    func loadNotesForSelectedProfile() async {
        guard let currentProfile = selectedProfile else { return }
        guard currentProfile.notes.isEmpty else {
             print("Notes for '\(currentProfile.name)' seem to be already in memory or load initiated.")
            return
        }
        let profileId = currentProfile.id
        print("Loading notes from DB for profile: \(currentProfile.name) (\(profileId))")
        do {
            let dbNotes = try await DatabaseManager.shared.fetchNoteEntries(profileId: profileId)
            var appNotesDict: [String: [Profile.NoteEntry]] = [:]
            for dbNote in dbNotes {
                let appNote = Profile.NoteEntry(id: dbNote.id, text: dbNote.text, timestamp: dbNote.timestamp)
                appNotesDict[dbNote.verseReference, default: []].append(appNote)
            }
            appNotesDict.forEach { key, value in appNotesDict[key] = value.sorted(by: { $0.timestamp < $1.timestamp }) }
            if let index = self.profiles.firstIndex(where: { $0.id == profileId }) {
                self.profiles[index].notes = appNotesDict
                if self.selectedProfile?.id == profileId {
                    self.selectedProfile?.notes = appNotesDict
                }
                print("Notes loaded into memory for profile '\(self.profiles[index].name)'. Count: \(dbNotes.count)")
            }
        } catch {
            print("Failed to load notes for profile \(profileId): \(error.localizedDescription)")
        }
    }

    func addOrUpdateNote(text: String, for verseRef: String, existingNoteId: UUID? = nil, associatedHashtags: [String] = []) async {
        guard let currentProfile = selectedProfile else { return }
        let profileId = currentProfile.id
        let noteId = existingNoteId ?? UUID()
        let timestamp = Date()
        let appNote = Profile.NoteEntry(id: noteId, text: text, timestamp: timestamp)
        let dbNote = DBNoteEntry(id: noteId, profileId: profileId, verseReference: verseRef, text: text, timestamp: timestamp)
        do {
            try await DatabaseManager.shared.saveNoteEntry(dbNote)
            for tagName in associatedHashtags {
                let dbHashtag = try await DatabaseManager.shared.fetchOrCreateHashtag(tagName: tagName)
                try await DatabaseManager.shared.linkNote(noteId, toHashtag: dbHashtag.id)
            }
            print("Note for \(verseRef) saved to DB with ID \(noteId).")
            if let pIndex = self.profiles.firstIndex(where: { $0.id == profileId }) {
                var notesForVerse = self.profiles[pIndex].notes[verseRef, default: []]
                if let appNoteIndex = notesForVerse.firstIndex(where: { $0.id == noteId }) {
                    notesForVerse[appNoteIndex] = appNote
                } else {
                    notesForVerse.append(appNote)
                }
                notesForVerse.sort(by: { $0.timestamp < $1.timestamp })
                self.profiles[pIndex].notes[verseRef] = notesForVerse
                if self.selectedProfile?.id == profileId { self.selectedProfile?.notes = self.profiles[pIndex].notes }
            }
        } catch {
            print("Failed to save note for \(verseRef): \(error.localizedDescription)")
        }
    }

    func deleteNote(noteId: UUID, from verseRef: String) async {
        guard let currentProfile = selectedProfile else { return }
        let profileId = currentProfile.id
        do {
            try await DatabaseManager.shared.deleteNoteEntry(id: noteId)
            print("Note ID \(noteId) deleted from DB.")
            if let pIndex = self.profiles.firstIndex(where: { $0.id == profileId }) {
                var notesForVerse = self.profiles[pIndex].notes[verseRef, default: []]
                notesForVerse.removeAll(where: { $0.id == noteId })
                if notesForVerse.isEmpty { self.profiles[pIndex].notes.removeValue(forKey: verseRef) }
                else { self.profiles[pIndex].notes[verseRef] = notesForVerse }
                if self.selectedProfile?.id == profileId { self.selectedProfile?.notes = self.profiles[pIndex].notes }
            }
        } catch {
            print("Failed to delete note \(noteId): \(error.localizedDescription)")
        }
    }

    func addHashtag(_ tagName: String, toNote noteId: UUID) async {
        let normalizedTag = tagName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTag.isEmpty else { return }
        do {
            let dbHashtag = try await DatabaseManager.shared.fetchOrCreateHashtag(tagName: normalizedTag)
            try await DatabaseManager.shared.linkNote(noteId, toHashtag: dbHashtag.id)
            print("Hashtag '\(normalizedTag)' linked to note \(noteId)")
        } catch {
            print("Failed to add/link hashtag '\(normalizedTag)' to note \(noteId): \(error.localizedDescription)")
        }
    }

    func removeHashtag(_ tagName: String, fromNote noteId: UUID) async {
        let normalizedTag = tagName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTag.isEmpty else { return }
        do {
            if let dbHashtag = try? await DatabaseManager.shared.fetchOrCreateHashtag(tagName: normalizedTag) {
                try await DatabaseManager.shared.unlinkNote(noteId, fromHashtag: dbHashtag.id)
                print("Hashtag '\(normalizedTag)' unlinked from note \(noteId)")
            }
        } catch {
            print("Failed to unlink hashtag '\(normalizedTag)' from note \(noteId): \(error.localizedDescription)")
        }
    }

    func getHashtagsForNote(noteId: UUID) async -> [String] {
        do {
            let dbHashtags = try await DatabaseManager.shared.fetchHashtagsForNote(noteId)
            return dbHashtags.map { $0.tagName }
        } catch {
            print("Failed to fetch hashtags for note \(noteId): \(error.localizedDescription)")
            return []
        }
    }
    
    func filteredNotes() -> [NoteDisplayEntry] {
        var notesToDisplay: [NoteDisplayEntry] = []
        let effectiveSearchQuery = self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if isAllNodes {
            for profile in profiles {
                for (verseRef, noteEntries) in profile.notes {
                    for appNote in noteEntries {
                        if shouldDisplayNote(appNote, verseRef: verseRef, profileName: profile.name, profileNodeType: profile.nodeType, searchQuery: effectiveSearchQuery) {
                            notesToDisplay.append(NoteDisplayEntry(
                                id: appNote.id.uuidString + "_\(profile.id.uuidString)",
                                verseRef: "\(profile.name): \(verseRef)", note: appNote, profileId: profile.id))
                        }
                    }
                }
            }
        } else if let currentProfile = selectedProfile {
            for (verseRef, noteEntries) in currentProfile.notes {
                for appNote in noteEntries {
                     if shouldDisplayNote(appNote, verseRef: verseRef, profileName: currentProfile.name, profileNodeType: currentProfile.nodeType, searchQuery: effectiveSearchQuery) {
                        notesToDisplay.append(NoteDisplayEntry(
                            id: appNote.id.uuidString,
                            verseRef: verseRef, note: appNote, profileId: currentProfile.id))
                    }
                }
            }
        }
        switch sortBy {
        case .canon: notesToDisplay.sort { $0.verseRef.localizedStandardCompare($1.verseRef) == .orderedAscending }
        case .fresh: notesToDisplay.sort { $0.note.timestamp > $1.note.timestamp }
        case .olden: notesToDisplay.sort { $0.note.timestamp < $1.note.timestamp }
        }
        return notesToDisplay
    }

    private func shouldDisplayNote(_ appNote: Profile.NoteEntry, verseRef: String, profileName: String, profileNodeType: Profile.NodeType, searchQuery: String) -> Bool {
        if !searchQuery.isEmpty {
            let matchSearch = appNote.text.lowercased().contains(searchQuery) ||
                              verseRef.lowercased().contains(searchQuery) ||
                              profileName.lowercased().contains(searchQuery)
            if !matchSearch { return false }
        }
        if profileNodeType == .scripture && selectedBook != "All Books" {
            if !verseRef.lowercased().hasPrefix(selectedBook.lowercased()) {
                return false
            }
        }
        return true
    }

    func versesForChapter(book: String, chapter: Int) -> [BibleVerse] {
        let versionKey = selectedProfile?.scriptureVersion ?? "kjv"
        let version = VerseLoader.BibleVersion(rawValue: versionKey) ?? .kjv
        return verseLoader.getVersesForChapter(book: book, chapter: chapter, version: version)
    }

    func searchVerses(query: String) -> [(reference: String, book: String, chapterVerse: String, text: String)] {
        let versionKey = selectedProfile?.scriptureVersion ?? "kjv"
        let version = VerseLoader.BibleVersion(rawValue: versionKey) ?? .kjv
        return verseLoader.searchVerses(query: query, version: version, bookAbbreviations: Self.bookAbbreviations)
    }
    
    func abbreviateBook(_ book: String) -> String { Self.bookAbbreviations[book] ?? book }
    
    func exportProfile(id: UUID, scope: ExportScope, completion: @MainActor @escaping (URL?) -> Void) {
        let bookForScope = (scope == .specificBook) ? self.selectedBook : "All Books"
        Task {
            do {
                guard let dbProfile = try await DatabaseManager.shared.fetchProfile(id: id) else {
                    throw NSError(domain: "Export", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found in DB."])
                }
                var notesForExportDict: [String: [Profile.NoteEntry]] = [:]
                let allDbNotesForProfile = try await DatabaseManager.shared.fetchNoteEntries(profileId: id)
                for dbNote in allDbNotesForProfile {
                    if dbProfile.nodeType == .scripture && scope == .specificBook && bookForScope != "All Books" {
                        if !dbNote.verseReference.lowercased().hasPrefix(bookForScope.lowercased()) { continue }
                    }
                    notesForExportDict[dbNote.verseReference, default: []].append(Profile.NoteEntry(id: dbNote.id, text: dbNote.text, timestamp: dbNote.timestamp))
                }
                notesForExportDict.forEach { key, value in notesForExportDict[key] = value.sorted(by: { $0.timestamp < $1.timestamp }) }
                let appProfileToExport = Profile(id: dbProfile.id, name: dbProfile.name, nodeType: dbProfile.nodeType,
                                                 scriptureVersion: dbProfile.scriptureVersion,
                                                 codexDocumentId: dbProfile.codexDocumentId, notes: notesForExportDict)
                let data = try JSONEncoder().encode(appProfileToExport)
                let tempDir = FileManager.default.temporaryDirectory
                let saneName = appProfileToExport.name.replacingOccurrences(of: "[^a-zA-Z0-9_.-]", with: "_", options: .regularExpression)
                let fileURL = tempDir.appendingPathComponent("\(saneName)_export.json")
                try data.write(to: fileURL)
                completion(fileURL)
            } catch {
                print("Export error for profile ID \(id): \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    func importProfile(from url: URL, name: String, completion: @MainActor @escaping (Bool, String?) -> Void) {
        Task {
            var errorMessage: String?
            do {
                guard url.startAccessingSecurityScopedResource() else { throw NSError(domain: "Import", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to access file (security)."]) }
                defer { url.stopAccessingSecurityScopedResource() }
                let fileData = try Data(contentsOf: url)
                let importedAppProfile = try JSONDecoder().decode(Profile.self, from: fileData)
                let newDbProfileId = UUID()
                let dbProfileToSave = DBProfile(id: newDbProfileId, name: name, nodeType: importedAppProfile.nodeType,
                                              scriptureVersion: importedAppProfile.scriptureVersion,
                                              codexDocumentId: importedAppProfile.codexDocumentId)
                try await DatabaseManager.shared.saveProfile(dbProfileToSave)
                for (verseRef, noteEntriesArray) in importedAppProfile.notes {
                    for appNote in noteEntriesArray {
                        let dbNote = DBNoteEntry(id: appNote.id, profileId: newDbProfileId, verseReference: verseRef,
                                                 text: appNote.text, timestamp: appNote.timestamp)
                        try await DatabaseManager.shared.saveNoteEntry(dbNote)
                    }
                }
                await self.loadProfilesFromDB()
                completion(true, nil)
            } catch {
                errorMessage = "Failed to import profile from JSON: \(error.localizedDescription)."
                print("Profile import error: \(errorMessage!)")
                completion(false, errorMessage)
            }
        }
    }
    
    func mergeImportedProfile(from url: URL, into existingProfileId: UUID, completion: @MainActor @escaping (Bool, String?) -> Void) {
        Task {
            var errorMessage: String?
            do {
                guard let targetDbProfile = try await DatabaseManager.shared.fetchProfile(id: existingProfileId) else {
                    throw NSError(domain: "Merge", code: 1, userInfo: [NSLocalizedDescriptionKey: "Target profile for merge not found in DB."])
                }
                guard targetDbProfile.nodeType == .scripture else {
                    throw NSError(domain: "Merge", code: 2, userInfo: [NSLocalizedDescriptionKey: "Merging is only supported for Scripture nodes."])
                }
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "Merge", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to access file for merging (security)."])
                }
                defer { url.stopAccessingSecurityScopedResource() }
                let fileData = try Data(contentsOf: url)
                let importedAppProfile = try JSONDecoder().decode(Profile.self, from: fileData)
                guard importedAppProfile.nodeType == .scripture else {
                    throw NSError(domain: "Merge", code: 4, userInfo: [NSLocalizedDescriptionKey: "Cannot merge: Imported file is not a Scripture node."])
                }
                for (verseRef, newNotesArray) in importedAppProfile.notes {
                    let existingDbNotesForVerse = try await DatabaseManager.shared.fetchNoteEntries(profileId: existingProfileId, verseRef: verseRef)
                    for newAppNote in newNotesArray {
                        let alreadyExists = existingDbNotesForVerse.contains { dbNote in
                            dbNote.text == newAppNote.text && Calendar.current.isDate(dbNote.timestamp, equalTo: newAppNote.timestamp, toGranularity: .second)
                        }
                        if !alreadyExists {
                            let dbNoteToSave = DBNoteEntry(id: newAppNote.id, profileId: existingProfileId, verseReference: verseRef,
                                                           text: newAppNote.text, timestamp: newAppNote.timestamp)
                            try await DatabaseManager.shared.saveNoteEntry(dbNoteToSave)
                        }
                    }
                }
                if self.selectedProfile?.id == existingProfileId { await self.loadNotesForSelectedProfile() }
                completion(true, nil)
            } catch {
                errorMessage = "Failed to merge profile: \(error.localizedDescription)."
                print("Profile merge error: \(errorMessage!)")
                completion(false, errorMessage)
            }
        }
    }
}
