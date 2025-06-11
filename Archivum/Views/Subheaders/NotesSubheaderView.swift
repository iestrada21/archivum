import SwiftUI

struct NotesSubheaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @Binding var navigationState: ContentView.NavigationState
    @State private var searchQuery: String = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button(notesManager.isAllNodes ? "All Nodes" : (notesManager.selectedProfile?.name ?? "Select Node")) {
                    navigationState = .profileSelection
                }
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                .frame(width: 140, height: 30)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                )

                TextField("Search Notes", text: $searchQuery)
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .background(themeManager.backgroundColor)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 180, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                    )
                    .onChange(of: searchQuery) { _, newValue in
                        notesManager.searchQuery = newValue
                    }

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

                Button(sortOptionLabel) {
                    notesManager.toggleSortBy()
                }
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                .frame(width: 100, height: 30)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                )
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
        }
        .background(themeManager.backgroundColor)
    }

    private var sortOptionLabel: String {
        switch notesManager.sortBy {
        case .canon: return "Canon"
        case .fresh: return "Fresh"
        case .olden: return "Olden"
        }
    }
}

struct NotesSubheaderView_Previews: PreviewProvider {
    static var previews: some View {
        NotesSubheaderView(
            notesManager: NotesManager(),
            navigationState: .constant(.notes)
        )
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
    }
}
