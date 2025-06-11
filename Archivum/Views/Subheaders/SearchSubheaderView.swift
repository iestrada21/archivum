import SwiftUI

struct SearchSubheaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @Binding var searchQuery: String
    @Binding var searchType: SearchView.SearchType
    @Binding var scriptureScope: SearchView.ScriptureSearchScope
    @Binding var showScopeOptions: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button("Scripture") {
                    searchType = .scripture
                    searchQuery = ""
                    showScopeOptions = false
                }
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                .foregroundColor(searchType == .scripture ? (themeManager.isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)) : themeManager.themeColor.opacity(themeManager.fontOpacity))
                .opacity(searchType == .scripture ? 1.0 : themeManager.fontOpacity)
                .frame(width: 140, height: 30)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                )

                Button("Codex Archive") {
                    searchType = .codex
                    searchQuery = ""
                    showScopeOptions = false
                }
                .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                .foregroundColor(searchType == .codex ? (themeManager.isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)) : themeManager.themeColor.opacity(themeManager.fontOpacity))
                .opacity(searchType == .codex ? 1.0 : themeManager.fontOpacity)
                .frame(width: 140, height: 30)
                .overlay(
                    Rectangle()
                        .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                )

                TextField("Search Archive", text: $searchQuery)
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .background(themeManager.backgroundColor)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .frame(width: 200, height: 30)
                    .overlay(
                        Rectangle()
                            .stroke(themeManager.themeColor.opacity(themeManager.fontOpacity), lineWidth: themeManager.lineWidth)
                    )

                Button(searchType == .scripture ? scopeLabel : (notesManager.selectedCodexDocumentId != nil ? notesManager.codexManager.getDocument(id: notesManager.selectedCodexDocumentId!)?.title ?? "Select Document" : "Select Document")) {
                    showScopeOptions.toggle()
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
        }
        .background(themeManager.backgroundColor)
    }

    private var scopeLabel: String {
        switch scriptureScope {
        case .all: return "All Books"
        case .byProfile: return notesManager.selectedProfile?.name ?? "By Profile"
        case .byBook: return notesManager.selectedBook
        }
    }
}

struct SearchSubheaderView_Previews: PreviewProvider {
    static var previews: some View {
        SearchSubheaderView(
            notesManager: NotesManager(),
            searchQuery: .constant(""),
            searchType: .constant(.scripture),
            scriptureScope: .constant(.all),
            showScopeOptions: .constant(false)
        )
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
    }
}
