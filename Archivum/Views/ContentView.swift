import SwiftUI

// Extension to define the .if modifier for SettingsView compatibility
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ContentView: View {
    @StateObject private var notesManager = NotesManager()
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var activeTab = UserDefaults.standard.string(forKey: "activeTab") ?? "Scripture"
    @State private var selectedVerse: String?
    @State private var navigationState: NavigationState = .verses
    @State private var dataMode: DataMode = .scripture
    @State private var noteToExpunge: NoteToExpunge?
    @State private var profileToExpungeId: UUID?
    @State private var noteToAmend: NoteToAmend?
    @State private var profileToAmendId: UUID?
    @State private var codexToAmendId: UUID?
    @State private var codexToExpungeId: UUID?
    @State private var searchQuery: String = ""
    @State private var searchType: SearchView.SearchType = .scripture
    @State private var scriptureScope: SearchView.ScriptureSearchScope = .all
    @State private var showScopeOptions: Bool = false

    private let tabs = ["Scripture", "Notes", "Search", "Codex", "Data", "Settings"]

    enum NavigationState {
        case verses
        case bookSelection
        case chapterSelection
        case profileSelection
        case notes
        case profileExpungeConfirm
        case noteExpungeConfirm
        case noteAmend
        case noteActionPane
        case profileAmend
        case codexNodeSelection
        case codexChapterSelection
        case codexAmend
        case codexExpungeConfirm
    }

    enum DataMode {
        case scripture
        case codex
    }

    struct NoteToExpunge {
        let verseRef: String
        let index: Int
        let noteId: UUID
    }

    struct NoteToAmend {
        let verseRef: String
        let index: Int
        let note: Profile.NoteEntry
        let profileId: UUID?
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main Header
            ZStack {
                HStack(spacing: 0) {
                    Text("ARCHIVUM")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 18)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.leading, 10)
                        .frame(height: 44)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(tabs, id: \.self) { tab in
                                HStack(spacing: 0) {
                                    Text(tab)
                                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                        .foregroundColor(activeTab == tab ? (themeManager.isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)) : themeManager.themeColor.opacity(themeManager.fontOpacity))
                                        .padding(.horizontal, 5)
                                        .gesture(
                                            TapGesture(count: 2)
                                                .onEnded { resetTab(tab) }
                                                .simultaneously(with: TapGesture()
                                                    .onEnded { switchTab(tab) })
                                        )

                                    if tab != tabs.last {
                                        Rectangle()
                                            .fill(themeManager.lineStroke)
                                            .frame(width: themeManager.lineWidth, height: 20)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 5)
                        .frame(height: 44)
                    }
                    .padding(.leading, 30)
                }
            }
            .background(themeManager.backgroundColor)
            // Horizontal line below Main Header
            Rectangle()
                .fill(themeManager.lineStroke)
                .frame(height: themeManager.lineWidth)

            // SubHeader
            ZStack {
                Group {
                    switch activeTab {
                    case "Scripture":
                        ScriptureSubheaderView(notesManager: notesManager, navigationState: $navigationState)
                    case "Notes":
                        NotesSubheaderView(notesManager: notesManager, navigationState: $navigationState)
                    case "Data":
                        HStack(spacing: 10) {
                            Spacer()
                            Button("Scripture Nodes") {
                                dataMode = .scripture
                                navigationState = .verses
                            }
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                            .foregroundColor(dataMode == .scripture ? (themeManager.isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)) : themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .frame(width: 160, height: 30)
                            .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))

                            Button("Codex Nodes") {
                                dataMode = .codex
                                navigationState = .verses
                            }
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                            .foregroundColor(dataMode == .codex ? (themeManager.isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)) : themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .frame(width: 160, height: 30)
                            .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 44)
                    case "Search":
                        SearchSubheaderView(notesManager: notesManager, searchQuery: $searchQuery, searchType: $searchType, scriptureScope: $scriptureScope, showScopeOptions: $showScopeOptions)
                    case "Settings":
                        HStack(spacing: 10) {
                            Spacer()
                            Button("Light Mode") {
                                themeManager.isDarkMode = false
                            }
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                            .foregroundColor(themeManager.isDarkMode ? themeManager.themeColor.opacity(themeManager.fontOpacity) : Color(red: 0.2, green: 0.2, blue: 0.2))
                            .frame(width: 140, height: 30)
                            .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))

                            Button("Dark Mode") {
                                themeManager.isDarkMode = true
                            }
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                            .foregroundColor(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .frame(width: 140, height: 30)
                            .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 44)
                    case "Codex":
                        CodexSubheaderView(notesManager: notesManager, navigationState: $navigationState)
                    default:
                        EmptyView()
                    }
                }
            }
            .background(themeManager.backgroundColor)
            // Horizontal line below SubHeader
            Rectangle()
                .fill(themeManager.lineStroke)
                .frame(height: themeManager.lineWidth)

            Spacer().frame(height: 10)

            // Main Content (Archive Pane)
            ZStack {
                mainContentView
                if navigationState == .noteActionPane {
                    NoteActionPaneView(
                        verseRef: noteToExpunge?.verseRef ?? "",
                        noteIndex: noteToExpunge?.index ?? 0, // Index for context if needed
                        onAmend: {
                            // Ensure we use the noteId from noteToExpunge to fetch the correct note for amending
                            if let expungeInfo = noteToExpunge, // This now has noteId
                               let currentSelectedProfile = notesManager.selectedProfile,
                               let notesForVerse = currentSelectedProfile.notes[expungeInfo.verseRef],
                               let noteToActuallyAmend = notesForVerse.first(where: { $0.id == expungeInfo.noteId }) { // Find by ID
                                
                                noteToAmend = NoteToAmend(
                                    verseRef: expungeInfo.verseRef,
                                    index: expungeInfo.index, // Pass index along if NoteAmendView uses it
                                    note: noteToActuallyAmend, // Pass the full, correct note entry
                                    profileId: currentSelectedProfile.id
                                )
                                navigationState = .noteAmend
                            } else {
                                // Handle case where note couldn't be found, perhaps reset state
                                navigationState = .verses
                                self.noteToExpunge = nil
                            }
                        },
                        onExpunge: {
                            navigationState = .noteExpungeConfirm
                        },
                        onCancel: {
                            navigationState = .verses
                            noteToExpunge = nil
                        }
                    )
                    .frame(width: 200, height: 150)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                }
            }
            .background(themeManager.backgroundColor)

            // Horizontal line above Bottom Header
            Rectangle()
                .fill(themeManager.lineStroke)
                .frame(height: themeManager.lineWidth)

            // Bottom Header
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 44)
                bottomHeaderContent
            }
            .background(themeManager.backgroundColor)
        }
        .background(themeManager.backgroundColor)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .onChange(of: activeTab) { newValue in //
                    UserDefaults.standard.set(newValue, forKey: "activeTab")
                }
    }

    private func switchTab(_ tab: String) {
        activeTab = tab
        if tab == "Scripture" && navigationState != .verses {
            navigationState = .verses
            if notesManager.selectedBook == "All Books" { notesManager.selectedBook = "Genesis" }
        } else if tab == "Notes" && navigationState != .notes {
            navigationState = .notes
            notesManager.selectedBook = "All Books"
        } else if tab == "Data" || tab == "Settings" || tab == "Codex" {
            navigationState = .verses
        } else if tab == "Search" {
            navigationState = .verses
            searchType = .scripture
            searchQuery = ""
            scriptureScope = .all
            showScopeOptions = false
        }
    }

    private func resetTab(_ tab: String) {
        switch tab {
        case "Scripture":
            notesManager.selectedBook = "Genesis"
            notesManager.selectedChapter = 1
            selectedVerse = nil
            navigationState = .verses
        case "Notes":
            notesManager.searchQuery = ""
            notesManager.sortBy = .canon
            notesManager.selectedBook = "All Books"
            navigationState = .notes
        case "Search":
            searchQuery = ""
            searchType = .scripture
            scriptureScope = .all
            showScopeOptions = false
        default:
            break
        }
    }

    private var versesContentView: some View {
        switch activeTab {
        case "Scripture":
            return AnyView(ScriptureView(notesManager: notesManager, selectedVerse: $selectedVerse, navigationState: $navigationState, noteToExpunge: $noteToExpunge, noteToAmend: $noteToAmend))
        case "Notes":
            return AnyView(NotesView(notesManager: notesManager, navigationState: $navigationState, noteToExpunge: $noteToExpunge, noteToAmend: $noteToAmend))
        case "Data":
            return AnyView(DataView(notesManager: notesManager, dataMode: $dataMode)
                .padding(.vertical, 1))
        case "Search":
            return AnyView(SearchView(notesManager: notesManager, searchQuery: $searchQuery, searchType: $searchType, scriptureScope: $scriptureScope, showScopeOptions: $showScopeOptions)
                .padding(.vertical, 1))
        case "Settings":
            return AnyView(SettingsView()
                .padding(.vertical, 1))
        case "Codex":
            return AnyView(CodexView(
                notesManager: notesManager,
                selectedVerse: $selectedVerse,
                navigationState: $navigationState,
                noteToExpunge: $noteToExpunge,
                noteToAmend: $noteToAmend))
        default:
            return AnyView(EmptyView())
        }
    }

    private var mainContentView: some View {
            Group {
                switch navigationState {
                case .verses:
                    versesContentView
                    
                case .bookSelection:
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            if activeTab == "Notes" {
                                Text("All Books")
                                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(themeManager.backgroundColor)
                                    .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))
                                    .onTapGesture {
                                        notesManager.selectedBook = "All Books"
                                        navigationState = .notes
                                    }
                            }
                            ForEach(["Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth",
                                     "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
                                     "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon",
                                     "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
                                     "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah",
                                     "Malachi", "Matthew", "Mark", "Luke", "John", "Acts", "Romans", "1 Corinthians",
                                     "2 Corinthians", "Galatians", "Ephesians", "Philippians", "Colossians", "1 Thessalonians",
                                     "2 Thessalonians", "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James",
                                     "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"], id: \.self) { book in
                                Text(book)
                                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(themeManager.backgroundColor)
                                    .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))
                                    .onTapGesture {
                                        notesManager.selectedBook = book
                                        navigationState = activeTab == "Scripture" ? .chapterSelection : .notes
                                    }
                            }
                        }
                        .padding(10)
                    }
                    
                case .chapterSelection:
                    if let chapterCount = notesManager.chapterCounts[notesManager.selectedBook] {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 10)], spacing: 10) {
                                ForEach(1...chapterCount, id: \.self) { chapter in
                                    Text(String(chapter))
                                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                        .padding(.vertical, 5)
                                        .frame(width: 60, height: 40)
                                        .background(themeManager.backgroundColor)
                                        .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))
                                        .monospacedDigit()
                                        .onTapGesture {
                                            notesManager.selectedChapter = chapter
                                            navigationState = .verses
                                        }
                                }
                            }
                            .padding(10)
                        }
                    } else {
                        EmptyView()
                    }
                    
                case .profileSelection:
                    ProfileSelectionView(notesManager: notesManager, isNotesTab: activeTab == "Notes", navigationState: $navigationState, profileToExpungeId: $profileToExpungeId, profileToAmendId: $profileToAmendId) {
                        navigationState = activeTab == "Scripture" ? .verses : .notes
                    }
                    
                case .notes:
                    NotesView(notesManager: notesManager, navigationState: $navigationState, noteToExpunge: $noteToExpunge, noteToAmend: $noteToAmend)
                    
                case .profileExpungeConfirm:
                    ProfileExpungeConfirmView(notesManager: notesManager, profileId: profileToExpungeId, onConfirm: {
                        if let id = profileToExpungeId {
                            Task { await notesManager.deleteProfile(id: id) } // <<-- MODIFIED
                        }
                        navigationState = .profileSelection
                        profileToExpungeId = nil
                    }, onCancel: {
                        navigationState = .profileSelection
                        profileToExpungeId = nil
                    })
                    
                case .noteExpungeConfirm:
                    NoteExpungeConfirmView(notesManager: notesManager, noteToExpunge: noteToExpunge, onConfirm: {
                        if let noteInfo = noteToExpunge { // noteToExpunge now contains noteId
                            Task { // <<-- MODIFIED
                                // Call the correct async method on NotesManager
                                await notesManager.deleteNote(noteId: noteInfo.noteId, from: noteInfo.verseRef)
                            }
                        }
                        navigationState = .verses // Or desired state
                        noteToExpunge = nil
                    }, onCancel: {
                        navigationState = .verses
                        noteToExpunge = nil
                    })
                    
                case .noteAmend:
                    if let amendInfo = noteToAmend { // amendInfo contains note.id (the UUID)
                        NoteAmendView(
                            notesManager: notesManager,
                            verseRef: amendInfo.verseRef,
                            noteIndex: amendInfo.index, // May still be useful for UI state if NoteAmendView uses it
                            note: amendInfo.note,       // This is the Profile.NoteEntry to amend
                            profileId: amendInfo.profileId ?? notesManager.selectedProfile?.id, // Ensure profileId context
                            onConfirm: { updatedText in
                                Task { // <<-- MODIFIED
                                    // Call the correct async method on NotesManager
                                    await notesManager.addOrUpdateNote(
                                        text: updatedText,
                                        for: amendInfo.verseRef,
                                        existingNoteId: amendInfo.note.id // Pass the existing note's ID
                                    )
                                }
                                navigationState = .verses // Or desired state
                                noteToAmend = nil
                            },
                            onCancel: {
                                navigationState = .verses
                                noteToAmend = nil
                            }
                        )
                    } else {
                        EmptyView()
                    }
                    
                case .noteActionPane:
                    EmptyView() // Handled in ZStack overlay
                    
                case .profileAmend:
                    if let profileId = profileToAmendId, let profile = notesManager.profiles.first(where: { $0.id == profileId }) {
                        ProfileAmendView(notesManager: notesManager, profileId: profileId, profileName: profile.name, onConfirm: { newName in
                            if !newName.isEmpty {
                                Task { await notesManager.renameProfile(id: profileId, newName: newName) } // <<-- MODIFIED
                            }
                            navigationState = .profileSelection
                            profileToAmendId = nil
                        }, onCancel: {
                            navigationState = .profileSelection
                            profileToAmendId = nil
                        })
                    } else {
                        EmptyView()
                    }
                    
                case .codexNodeSelection:
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(notesManager.codexManager.documents, id: \.id) { document in
                                HStack(spacing: 5) {
                                    Text(document.title)
                                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(themeManager.backgroundColor)
                                        .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))
                                        .onTapGesture {
                                            notesManager.selectedCodexDocumentId = document.id
                                            navigationState = .codexChapterSelection
                                        }

                                    Button("Amend") {
                                        codexToAmendId = document.id
                                        navigationState = .codexAmend
                                    }
                                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                    .padding(.vertical, 5).padding(.horizontal, 10).frame(width: 70, height: 30)
                                    .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))

                                    Button("Expunge") {
                                        codexToExpungeId = document.id
                                        navigationState = .codexExpungeConfirm
                                    }
                                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                    .padding(.vertical, 5).padding(.horizontal, 10).frame(width: 70, height: 30)
                                    .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))
                                }
                            }
                            if notesManager.codexManager.documents.isEmpty {
                                Text("No Nodes Available") // ...
                                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                    .padding(.vertical, 5).padding(.horizontal, 10)
                            }
                        }
                        .padding(10)
                    }
                    
                case .codexChapterSelection:
                    if let document = notesManager.codexManager.getDocument(id: notesManager.selectedCodexDocumentId ?? UUID()) {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 10)], spacing: 10) {
                                ForEach(document.chapters, id: \.number) { chapter in
                                    Text(String(chapter.number)) // ...
                                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                        .padding(.vertical, 5).frame(width: 60, height: 40)
                                        .background(themeManager.backgroundColor)
                                        .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))
                                        .monospacedDigit()
                                        .onTapGesture {
                                            notesManager.selectedCodexChapter = chapter.number
                                            navigationState = .verses
                                        }
                                }
                            }
                            .padding(10)
                        }
                    } else {
                        Text("No Chapters Available") // ...
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .padding(.vertical, 10).padding(.horizontal, 15)
                    }
                    
                case .codexExpungeConfirm:
                    CodexExpungeConfirmView(
                        notesManager: notesManager,
                        codexId: codexToExpungeId,
                        onConfirm: {
                            if let id = codexToExpungeId {
                                notesManager.codexManager.deleteDocument(id: id) // Assuming this is synchronous
                            }
                            navigationState = .codexNodeSelection
                            codexToExpungeId = nil
                        },
                        onCancel: {
                            navigationState = .codexNodeSelection
                            codexToExpungeId = nil
                        }
                    )
                    
                case .codexAmend:
                    if let codexId = codexToAmendId, let document = notesManager.codexManager.getDocument(id: codexId) {
                        CodexAmendView(
                            notesManager: notesManager,
                            codexId: codexId,
                            codexTitle: document.title,
                            onConfirm: { newTitle in
                                if !newTitle.isEmpty {
                                    notesManager.codexManager.renameDocument(id: codexId, newTitle: newTitle) // Assuming this is synchronous
                                }
                                navigationState = .codexNodeSelection
                                codexToAmendId = nil
                            },
                            onCancel: {
                                navigationState = .codexNodeSelection
                                codexToAmendId = nil
                            }
                        )
                    } else {
                        EmptyView()
                    }
                }
            }
        }

    private var bottomHeaderContent: some View {
        Group {
            switch activeTab {
            case "Scripture":
                ScriptureView.bottomHeaderContent(notesManager: notesManager, themeManager: themeManager)
            case "Notes":
                HStack { Spacer(); Button("Clear Search") { notesManager.searchQuery = "" }.font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12))).foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity)); Spacer() }
                    .padding(.horizontal, 10)
                    .frame(height: 44)
            case "Data":
                HStack { Spacer(); Button("Back to Main") { navigationState = .verses }.font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12))).foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity)); Spacer() }
                    .padding(.horizontal, 10)
                    .frame(height: 44)
            case "Search":
                HStack { Spacer(); Text("Search Options").font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12))).foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity)); Spacer() }
                    .padding(.horizontal, 10)
                    .frame(height: 44)
            case "Settings":
                HStack { Spacer(); Button("Apply Changes") {}.font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12))).foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity)); Spacer() }
                    .padding(.horizontal, 10)
                    .frame(height: 44)
            case "Codex":
                CodexView.bottomHeaderContent(notesManager: notesManager, themeManager: themeManager)
            default:
                EmptyView()
            }
        }
    }
}

struct ProfileSelectionView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    let isNotesTab: Bool
    @Binding var navigationState: ContentView.NavigationState
    @Binding var profileToExpungeId: UUID?
    @Binding var profileToAmendId: UUID?
    let onSelect: () -> Void
    @State private var newProfileName: String = ""
    @FocusState private var isProfileFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if isNotesTab {
                    Text("All Nodes")
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
                            notesManager.selectAllNodes()
                            onSelect()
                        }
                }
                if notesManager.profiles.isEmpty {
                    Text("No Profiles Available")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                } else {
                    ForEach(notesManager.profiles) { profile in
                        HStack(spacing: 5) {
                            Text(profile.name)
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
                                    notesManager.selectProfile(id: profile.id)
                                    onSelect()
                                }

                            Button("Amend") {
                                profileToAmendId = profile.id
                                navigationState = .profileAmend
                            }
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .frame(width: 70, height: 30)
                            .overlay(
                                Rectangle()
                                    .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                            )

                            Button("Expunge") {
                                profileToExpungeId = profile.id
                                navigationState = .profileExpungeConfirm
                            }
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .frame(width: 70, height: 30)
                            .overlay(
                                Rectangle()
                                    .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                            )
                        }
                    }
                }

                HStack(spacing: 5) {
                    TextField("New Profile", text: $newProfileName)
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .background(themeManager.backgroundColor)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(
                            Rectangle()
                                .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                        )
                        .focused($isProfileFieldFocused)

                    Button("Register Node") {
                        if !newProfileName.isEmpty {
                                                    let name = newProfileName // Capture value for the Task
                                                    let type = isNotesTab ? Profile.NodeType.scripture : Profile.NodeType.scripture // Assuming this was the intended logic for type, or adjust as needed. If always .scripture for this view: Profile.NodeType.scripture

                                                    Task {
                                                        await notesManager.createProfile(name: name, nodeType: type)
                                                        // If you need to update UI state like newProfileName *after* creation,
                                                        // ensure it's done on the main actor, e.g.,
                                                        // await MainActor.run {
                                                        //     self.newProfileName = ""
                                                        //     self.isProfileFieldFocused = false
                                                        // }
                                                        // For now, clearing them immediately is often fine.
                                                    }
                                                    // These lines will execute immediately after starting the Task:
                                                    newProfileName = "" // [cite: 206]
                                                    isProfileFieldFocused = false // [cite: 206]
                                                }
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                }
                .padding(.top, 10)
            }
            .padding(10)
        }
        .background(themeManager.backgroundColor)
    }
}

struct ProfileExpungeConfirmView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    let profileId: UUID?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Expunge Node?")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)

                if let id = profileId, let profile = notesManager.profiles.first(where: { $0.id == id }) {
                    Text("Node: \(profile.name)")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                } else {
                    Text("Node: Not Found")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                }

                HStack(spacing: 5) {
                    Button("[Affirm Task]") {
                        onConfirm()
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 140, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                    )

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
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
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

struct ProfileAmendView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    let profileId: UUID
    let profileName: String
    @State private var newName: String
    @FocusState private var isTextFieldFocused: Bool
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    init(
        notesManager: NotesManager,
        profileId: UUID,
        profileName: String,
        onConfirm: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.notesManager = notesManager
        self.profileId = profileId
        self.profileName = profileName
        self._newName = State(initialValue: profileName)
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Amend Node?")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)

                Text("Node: \(profileName)")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)

                TextField("New Node Name", text: $newName)
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .background(themeManager.backgroundColor)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                    )
                    .focused($isTextFieldFocused)
                    .onAppear {
                        isTextFieldFocused = true
                    }

                HStack(spacing: 5) {
                    Button("[Affirm Task]") {
                        onConfirm(newName)
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 140, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                    )

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
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
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

struct NoteExpungeConfirmView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    let noteToExpunge: ContentView.NoteToExpunge?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Expunge Entry?")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)

                if let note = noteToExpunge,
                   let notes = notesManager.selectedProfile?.notes[note.verseRef] {
                    Text("Verse: \(note.verseRef)")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)

                    Text("Note: \(notes[note.index].text)")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 5) {
                    Button("[Affirm Task]") {
                        onConfirm()
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 140, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                    )

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
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
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

struct NoteAmendView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    let verseRef: String
    let noteIndex: Int
    let profileId: UUID?
    @State private var noteText: String
    @FocusState private var isNoteFieldFocused: Bool
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    init(
        notesManager: NotesManager,
        verseRef: String,
        noteIndex: Int,
        note: Profile.NoteEntry,
        profileId: UUID?,
        onConfirm: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.notesManager = notesManager
        self.verseRef = verseRef
        self.noteIndex = noteIndex
        self.profileId = profileId
        self._noteText = State(initialValue: note.text)
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Amend Entry")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)

                ScrollView(.vertical, showsIndicators: true) {
                    TextEditor(text: $noteText)
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .background(themeManager.backgroundColor)
                        .padding(.vertical, 5)
                        .padding(.horizontal,10)
                        .frame(minHeight: 60, maxHeight: 60)
                        .overlay(
                            Rectangle()
                                .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                        )
                        .focused($isNoteFieldFocused)
                        .onAppear {
                            isNoteFieldFocused = true
                        }
                }

                HStack(spacing: 5) {
                    Button("[Affirm Task]") {
                        if !noteText.isEmpty {
                            onConfirm(noteText)
                        }
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 140, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                    )

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
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
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

struct NoteActionPaneView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let verseRef: String
    let noteIndex: Int
    let onAmend: () -> Void
    let onExpunge: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                Text("Note Actions")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)

                Button("Amend Entry") {
                    onAmend()
                }
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .frame(width: 140, height: 30)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                )

                Button("Expunge Entry") {
                    onExpunge()
                }
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .frame(width: 140, height: 30)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                )

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
                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                )
            }
            .padding(20)
            .background(themeManager.backgroundColor)
        }
        .background(themeManager.backgroundColor)
    }
}

struct CodexExpungeConfirmView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    let codexId: UUID?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Expunge Codex Node?")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)

                if let id = codexId, let document = notesManager.codexManager.getDocument(id: id) {
                    Text("Node: \(document.title)")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                } else {
                    Text("Node: Not Found")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                }

                HStack(spacing: 5) {
                    Button("[Affirm Task]") {
                        onConfirm()
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 140, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                    )

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
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
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

struct CodexAmendView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    let codexId: UUID
    let codexTitle: String
    @State private var newTitle: String
    @FocusState private var isTextFieldFocused: Bool
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    init(
        notesManager: NotesManager,
        codexId: UUID,
        codexTitle: String,
        onConfirm: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.notesManager = notesManager
        self.codexId = codexId
        self.codexTitle = codexTitle
        self._newTitle = State(initialValue: codexTitle)
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Amend Codex Node?")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)

                Text("Node: \(codexTitle)")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)

                TextField("New Node Title", text: $newTitle)
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .background(themeManager.backgroundColor)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                    )
                    .focused($isTextFieldFocused)
                    .onAppear {
                        isTextFieldFocused = true
                    }

                HStack(spacing: 5) {
                    Button("[Affirm Task]") {
                        onConfirm(newTitle)
                    }
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 140, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                    )

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
                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ThemeManager())
            .environmentObject(NotesManager())
            .preferredColorScheme(.dark)
    }
}
