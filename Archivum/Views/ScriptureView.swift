import SwiftUI

struct ScriptureView: View {
    @ObservedObject var notesManager: NotesManager
    @Binding var selectedVerse: String?
    @Binding var navigationState: ContentView.NavigationState
    @Binding var noteToExpunge: ContentView.NoteToExpunge?
    @Binding var noteToAmend: ContentView.NoteToAmend?
    @EnvironmentObject private var themeManager: ThemeManager

    // Helper method to build the content for each verse
    @ViewBuilder
    private func verseRowAndNoteSection(verse: BibleVerse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Verse Row with Note Indicator
            HStack(alignment: .top, spacing: 15) {
                // Verse Citation with Note Indicator
                VStack(alignment: .leading, spacing: 0) {
                    Text(String(format: "[%02d]", verse.verse))
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .id("verse_\(verse.verse)") // For ScrollViewReader

                    if !(notesManager.selectedProfile?.notes[verse.reference]?.isEmpty ?? true) {
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
                selectedVerse = (selectedVerse == verse.reference) ? nil : verse.reference
            }

            // Note Section (Expandable)
            if selectedVerse == verse.reference {
                NoteSectionView(
                    notesManager: notesManager,
                    verseReference: verse.reference,
                    onExpunge: { verseRef, index in
                        // Attempt to find the actual note by index to get its ID
                        if let noteEntries = notesManager.selectedProfile?.notes[verseRef], index < noteEntries.count {
                            let actualNote = noteEntries[index]
                            noteToExpunge = ContentView.NoteToExpunge(verseRef: verseRef, index: index, noteId: actualNote.id)
                            navigationState = .noteExpungeConfirm
                        } else {
                            print("Error: Could not find note to expunge at \(verseRef) index \(index)")
                        }
                    },
                    onAmend: { verseRef, index, note in // 'note' here is Profile.NoteEntry
                        noteToAmend = ContentView.NoteToAmend(
                            verseRef: verseRef,
                            index: index,
                            note: note, // Profile.NoteEntry, which includes its 'id'
                            profileId: notesManager.selectedProfile?.id // Pass current profile ID
                        )
                        navigationState = .noteAmend
                    },
                    onShowActionPane: { verseRef, index in
                        // Attempt to find the actual note by index to get its ID
                        if let noteEntries = notesManager.selectedProfile?.notes[verseRef], index < noteEntries.count {
                            let actualNote = noteEntries[index]
                            noteToExpunge = ContentView.NoteToExpunge(verseRef: verseRef, index: index, noteId: actualNote.id)
                            navigationState = .noteActionPane
                        } else {
                            print("Error: Could not find note for action pane at \(verseRef) index \(index)")
                        }
                    }
                )
                .padding(.leading, 40) // Indent the note section under the verse text
                .background(themeManager.backgroundColor)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                )
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(notesManager.versesForChapter(book: notesManager.selectedBook, chapter: notesManager.selectedChapter)) { verse in
                        // Use the helper method here
                        verseRowAndNoteSection(verse: verse)
                    }
                }
                .padding(10)
            }
            .background(themeManager.backgroundColor)
            .onChange(of: notesManager.selectedChapter) { oldValue, newValue in // Explicitly name parameters
                withAnimation {
                    proxy.scrollTo("verse_1", anchor: .top)
                }
            }
            .onAppear { // .onAppear does not need oldValue, newValue
                withAnimation {
                    proxy.scrollTo("verse_1", anchor: .top)
                }
            }
        }
    }

    static func bottomHeaderContent(notesManager: NotesManager, themeManager: ThemeManager) -> some View {
        HStack {
            Spacer()
            Button("Previous") {
                if notesManager.selectedChapter > 1 {
                    notesManager.selectedChapter -= 1
                }
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
            .frame(width: 100, height: 30)
            .overlay(
                Rectangle()
                    .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
            )
            Spacer()
            Button("Next") {
                if let maxChapters = notesManager.chapterCounts[notesManager.selectedBook], notesManager.selectedChapter < maxChapters {
                    notesManager.selectedChapter += 1
                }
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
            .frame(width: 100, height: 30)
            .overlay(
                Rectangle()
                    .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
            )
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
    }
}
