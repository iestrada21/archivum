import SwiftUI

struct CodexView: View {
    @ObservedObject var notesManager: NotesManager
    @Binding var selectedVerse: String?
    @Binding var navigationState: ContentView.NavigationState
    @Binding var noteToExpunge: ContentView.NoteToExpunge?
    @Binding var noteToAmend: ContentView.NoteToAmend?
    @EnvironmentObject private var themeManager: ThemeManager

    // Helper function to build the content for a valid document and chapter
    @ViewBuilder
    private func chapterContentView(document: CodexDocument, chapter: Chapter) -> some View {
        ForEach(chapter.verses, id: \.number) { verse in
            let verseRef = "codex:\(document.id):\(chapter.number):\(verse.number)"
            VStack(alignment: .leading, spacing: 0) {
                // Verse Row
                HStack(alignment: .top, spacing: 15) {
                    VStack(alignment: .leading, spacing: 0) { // Citation column
                        Text(String(format: "[%02d]", verse.number))
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .monospacedDigit()
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .id("verse_\(verse.number)")

                        if !(notesManager.selectedProfile?.notes[verseRef]?.isEmpty ?? true) {
                            Text("▼")
                                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 8)))
                                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                .padding(.leading, 5)
                        }
                    }
                    .frame(width: 40, alignment: .leading)

                    Text(verse.text)
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedVerse = (selectedVerse == verseRef) ? nil : verseRef
                }

                // Note Section
                if selectedVerse == verseRef {
                    NoteSectionView(
                        notesManager: notesManager,
                        verseReference: verseRef,
                        onExpunge: { ref, index in // Ensure NoteToExpunge is created correctly
                            // You need the noteId from Profile.NoteEntry
                            // This part needs access to the actual note entry to get its ID
                            if let noteEntries = notesManager.selectedProfile?.notes[ref], index < noteEntries.count {
                                let noteEntry = noteEntries[index]
                                noteToExpunge = ContentView.NoteToExpunge(verseRef: ref, index: index, noteId: noteEntry.id)
                                navigationState = .noteExpungeConfirm
                            }
                        },
                        onAmend: { ref, index, note in // 'note' here is Profile.NoteEntry
                            noteToAmend = ContentView.NoteToAmend(verseRef: ref, index: index, note: note, profileId: notesManager.selectedProfile?.id)
                            navigationState = .noteAmend
                        },
                        onShowActionPane: { ref, index in // Similar to onExpunge, you need noteId
                            if let noteEntries = notesManager.selectedProfile?.notes[ref], index < noteEntries.count {
                                let noteEntry = noteEntries[index]
                                noteToExpunge = ContentView.NoteToExpunge(verseRef: ref, index: index, noteId: noteEntry.id)
                                navigationState = .noteActionPane
                            }
                        }
                    )
                    .background(themeManager.backgroundColor)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                    )
                }
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let documentId = notesManager.selectedCodexDocumentId,
                       let document = notesManager.codexManager.getDocument(id: documentId) {
                        
                        // Determine the chapter to display
                        let currentChapter = document.chapters.first { $0.number == notesManager.selectedCodexChapter } ?? document.chapters.first
                        
                        if let chapterToDisplay = currentChapter {
                            // Use the helper view/function here
                            chapterContentView(document: document, chapter: chapterToDisplay)
                        } else {
                            Text("No Chapters Available")
                                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 15)
                        }
                    } else {
                        Text("No Codex Document Selected")
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 15)
                    }
                }
                .padding(10)
            }
            .background(themeManager.backgroundColor)
            // .onChange - these should be fine
            .onChange(of: notesManager.selectedCodexChapter) {oldValue, newValue in // Use new signature
                withAnimation {
                    proxy.scrollTo("verse_1", anchor: .top)
                }
            }
            .onChange(of: notesManager.selectedCodexDocumentId) {oldValue, newValue in // Use new signature
                withAnimation {
                    proxy.scrollTo("verse_1", anchor: .top)
                }
            }
            .onAppear {
                withAnimation {
                    proxy.scrollTo("verse_1", anchor: .top)
                }
            }
        }
    }

    // ... (bottomHeaderContent remains the same) ...
    static func bottomHeaderContent(notesManager: NotesManager, themeManager: ThemeManager) -> some View {
        HStack {
            Spacer()
            Button("Previous") {
                if notesManager.selectedCodexChapter > 1 {
                    notesManager.selectedCodexChapter -= 1
                }
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
            .disabled(notesManager.selectedCodexChapter <= 1)
            Spacer()
            Button("Next") {
                if let document = notesManager.codexManager.getDocument(id: notesManager.selectedCodexDocumentId ?? UUID()),
                   let maxChapter = document.chapters.max(by: { $0.number < $1.number })?.number,
                   notesManager.selectedCodexChapter < maxChapter {
                    notesManager.selectedCodexChapter += 1
                }
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
            .disabled({
                guard let document = notesManager.codexManager.getDocument(id: notesManager.selectedCodexDocumentId ?? UUID()),
                      let maxChapter = document.chapters.max(by: { $0.number < $1.number })?.number else { return true }
                return notesManager.selectedCodexChapter >= maxChapter
            }())
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
    }
}

// Preview remains the same
struct CodexView_Previews: PreviewProvider {
    static var previews: some View {
        CodexView(
            notesManager: NotesManager(),
            selectedVerse: .constant(nil),
            navigationState: .constant(.verses),
            noteToExpunge: .constant(nil),
            noteToAmend: .constant(nil)
        )
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
    }
}
