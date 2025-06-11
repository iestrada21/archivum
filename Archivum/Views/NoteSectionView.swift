import SwiftUI

struct NoteSectionView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    let verseReference: String
    let onExpunge: (String, Int) -> Void
    let onAmend: (String, Int, Profile.NoteEntry) -> Void
    let onShowActionPane: (String, Int) -> Void
    @State private var noteDraft: String = ""
    @FocusState private var isNoteFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let notes = notesManager.selectedProfile?.notes[verseReference], !notes.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(notes.indices, id: \.self) { index in
                            Text("- \(notes[index].text)")
                                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .gesture(
                                    LongPressGesture(minimumDuration: 0.5)
                                        .onEnded { _ in
                                            onShowActionPane(verseReference, index)
                                        }
                                )
                        }
                    }
                }
                .frame(height: 70)
                .padding(.leading, 10)
                .padding(.vertical, 5)
            } else {
                Color.clear // Placeholder if no notes, to maintain layout
                    .frame(height: 70)
                    .padding(.leading, 10)
                    .padding(.vertical, 5)
            }

            HStack(spacing: 5) {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        TextField("Commit Record", text: $noteDraft)
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .background(themeManager.backgroundColor)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .frame(width: 250, height: 30) // Increased base width
                            .overlay(
                                Rectangle()
                                    .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                            )
                            .id("noteField_\(verseReference)")
                            .focused($isNoteFieldFocused)
                    }
                    .onChange(of: noteDraft) { newValue in // Explicitly named newValue for clarity
                        withAnimation {
                            proxy.scrollTo("noteField_\(verseReference)", anchor: .trailing) // Auto-scroll to last letter
                        }
                    }
                }

                Button("Seal Entry") {
                    // MODIFIED ACTION:
                    if notesManager.selectedProfile != nil, !noteDraft.isEmpty {
                        let draft = noteDraft // Capture current noteDraft for the Task
                        let currentVerseReference = verseReference // Capture verseReference

                        Task {
                            // Call the existing async method in NotesManager to add the note.
                            await notesManager.addOrUpdateNote(
                                text: draft,
                                for: currentVerseReference,
                                existingNoteId: nil, // This is for a new note
                                associatedHashtags: [] // Add hashtags if applicable from your UI
                            )
                            
                            // Resetting UI state after the async operation.
                            // This will run on the MainActor because the Button action is.
                            noteDraft = ""
                            isNoteFieldFocused = false
                        }
                    }
                }
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                .padding(.vertical, 5) // These modifiers were likely on the Button
                .padding(.horizontal, 10) // Make sure these match your original styling
            }
            .padding(.leading, 10)
            .padding(.bottom, 5)
        }
        .background(themeManager.backgroundColor)
    }
}

