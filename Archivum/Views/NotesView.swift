import SwiftUI

struct NotesView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @Binding var navigationState: ContentView.NavigationState
    @Binding var noteToExpunge: ContentView.NoteToExpunge?
    @Binding var noteToAmend: ContentView.NoteToAmend?
    @State private var selectedNote: NoteIdentifier?

    struct NoteIdentifier: Identifiable {
        let id: String
        let verseReference: String
        let index: Int
        let profileId: UUID?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                let filteredNotes = notesManager.filteredNotes()
                if filteredNotes.isEmpty {
                    Text("No Entries Herein")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(Array(filteredNotes.enumerated()), id: \.element.id) { index, noteEntry in
                                            // 'index' is now the actual integer index of the note in filteredNotes.
                                            // 'noteEntry' is the NotesManager.NoteDisplayEntry object.

                                            // 'localSelectedNoteId' is your local struct NoteIdentifier
                                            let localSelectedNoteId = NoteIdentifier(
                                                id: noteEntry.id, // This 'id' is the String ID from NoteDisplayEntry
                                                verseReference: noteEntry.verseRef,
                                                index: index,     // Use the 'index' from .enumerated()
                                                profileId: noteEntry.profileId
                                            )
                                            
                                            VStack(alignment: .leading, spacing: 0) {
                                                HStack {
                                                    Text(noteEntry.verseRef)
                                                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                                        .frame(width: 140, alignment: .leading)

                                                    Text(noteEntry.note.text) // noteEntry.note is Profile.NoteEntry
                                                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                                                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    selectedNote = (selectedNote?.id == localSelectedNoteId.id) ? nil : localSelectedNoteId
                                                }

                                                if selectedNote?.id == localSelectedNoteId.id {
                                                    NoteActionsView(
                                                        verseReference: noteEntry.verseRef,
                                                        noteIndex: index, // Pass the 'index' from .enumerated()
                                                        note: noteEntry.note, // This is the Profile.NoteEntry
                                                        profileId: noteEntry.profileId,
                                                        onAmend: {
                                                            // This part should be correct as NoteToAmend takes Profile.NoteEntry
                                                            noteToAmend = ContentView.NoteToAmend(
                                                                verseRef: noteEntry.verseRef,
                                                                index: index,
                                                                note: noteEntry.note, // noteEntry.note is Profile.NoteEntry
                                                                profileId: noteEntry.profileId
                                                            )
                                                            navigationState = .noteAmend
                                                        },
                                                        onExpunge: {
                                                            // This is where you create ContentView.NoteToExpunge
                                                            // It now needs the actual UUID of the note (noteEntry.note.id)
                                                            noteToExpunge = ContentView.NoteToExpunge(
                                                                verseRef: noteEntry.verseRef,
                                                                index: index,
                                                                noteId: noteEntry.note.id // <<-- Make sure Profile.NoteEntry has 'id' (UUID)
                                                                                           // and NoteDisplayEntry.note is that Profile.NoteEntry
                                                            )
                                                            navigationState = .noteExpungeConfirm
                                                        }
                                                    )
                                                    .background(themeManager.backgroundColor)
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                                                    )
                                                }
                                            }
                                        }
                }
            }
            .padding(10)
        }
        .background(themeManager.backgroundColor)
    }
}

struct NoteActionsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let verseReference: String
    let noteIndex: Int
    let note: Profile.NoteEntry
    let profileId: UUID?
    let onAmend: () -> Void
    let onExpunge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(timestampString)
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Amend Entry") {
                    onAmend()
                }
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .frame(width: 80, height: 30)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                )

                Button("Expunge Entry") {
                    onExpunge()
                }
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .frame(width: 80, height: 30)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
                )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
        }
        .background(themeManager.backgroundColor)
    }

    private var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddyy - HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: note.timestamp)
    }
}

struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NotesView(
            notesManager: NotesManager(),
            navigationState: .constant(.notes),
            noteToExpunge: .constant(nil),
            noteToAmend: .constant(nil)
        )
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
    }
}
