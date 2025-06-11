import SwiftUI

struct ScriptureSubheaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @Binding var navigationState: ContentView.NavigationState

    var body: some View {
        HStack {
            Button(notesManager.selectedBook) {
                navigationState = .bookSelection
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
            .frame(width: 140, height: 30)
            .overlay(
                Rectangle()
                    .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
            )

            Spacer()

            Button(String(notesManager.selectedChapter)) {
                navigationState = .chapterSelection
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
            .frame(width: 30, height: 30)
            .overlay(
                Rectangle()
                    .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
            )
            .monospacedDigit()

            Spacer()

            Button(notesManager.selectedProfile?.name ?? "None") {
                navigationState = .profileSelection
            }
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
            .frame(width: 140, height: 30)
            .overlay(
                Rectangle()
                    .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
            )
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(themeManager.backgroundColor)
    }
}

struct ScriptureSubheaderView_Previews: PreviewProvider {
    static var previews: some View {
        ScriptureSubheaderView(
            notesManager: NotesManager(),
            navigationState: .constant(.verses)
        )
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
    }
}
