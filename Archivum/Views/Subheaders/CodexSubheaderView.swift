import SwiftUI

struct CodexSubheaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @Binding var navigationState: ContentView.NavigationState

    var body: some View {
        HStack(spacing: 10) {
            Button(
                notesManager.selectedCodexDocumentId != nil ?
                (notesManager.codexManager.getDocument(id: notesManager.selectedCodexDocumentId!)?.title ?? "Select Node") :
                "Select Node"
            ) {
                navigationState = .codexNodeSelection
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
            .frame(width: 200, height: 30) // Increased from 140 to 200
            .overlay(
                Rectangle()
                    .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
            )

            Spacer()

            Button(
                notesManager.selectedCodexDocumentId != nil ?
                "Chapter \(notesManager.selectedCodexChapter)" :
                "No Chapter"
            ) {
                navigationState = .codexChapterSelection
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
            .frame(width: 100, height: 30)
            .overlay(
                Rectangle()
                    .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
            )
            .disabled(notesManager.selectedCodexDocumentId == nil)
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(themeManager.backgroundColor)
    }
}

struct CodexSubheaderView_Previews: PreviewProvider {
    static var previews: some View {
        CodexSubheaderView(
            notesManager: NotesManager(),
            navigationState: .constant(.verses)
        )
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
    }
}
