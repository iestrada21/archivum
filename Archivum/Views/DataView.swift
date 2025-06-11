import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main DataView
struct DataView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @Binding var dataMode: ContentView.DataMode
    @State private var activeTab: Tab = .export

    enum Tab {
        case export
        case importNode
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 10) {
                HStack(spacing: 0) {
                    Text("Export Node")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(activeTab == .export ? (themeManager.isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)) : themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.horizontal, 10)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                        .onTapGesture { activeTab = .export }

                    Rectangle()
                        .fill(themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .frame(width: themeManager.lineWidth, height: 20)

                    Text("Import Node")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(activeTab == .importNode ? (themeManager.isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)) : themeManager.themeColor.opacity(themeManager.fontOpacity))
                        .padding(.horizontal, 10)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                        .onTapGesture { activeTab = .importNode }
                }
                .padding(.vertical, 5)

                switch activeTab {
                case .export:
                    if dataMode == .scripture {
                        ScriptureExportView(notesManager: notesManager)
                    } else {
                        CodexExportView(notesManager: notesManager)
                    }
                case .importNode:
                    if dataMode == .scripture {
                        ScriptureImportView(notesManager: notesManager)
                    } else {
                        CodexImportView(notesManager: notesManager)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(themeManager.backgroundColor)
    }
}

// MARK: - Scripture Export View
struct ScriptureExportView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @State private var exportState: ExportState = .initial
    @State private var selectedProfileId: UUID?
    @State private var selectedBook: String = "All Books"
    @State private var isShareSheetPresented: Bool = false
    @State private var selectedFileURL: URL?
    @State private var exportMessage: String?

    enum ExportState {
        case initial, nodeSelected, selectingNode, selectingScope
    }
    
    init(notesManager: NotesManager) {
        self.notesManager = notesManager
    }

    var body: some View {
        Group {
            switch exportState {
            case .selectingNode:
                ExportProfileSelectionView(
                    notesManager: notesManager,
                    dataMode: ContentView.DataMode.scripture,
                    onSelect: { profileId in
                        selectedProfileId = profileId
                        exportState = .nodeSelected
                        exportMessage = "Node '\(notesManager.profiles.first(where: {$0.id == profileId})?.name ?? "Selected")' chosen. Now select scope."
                    },
                    onCancel: {
                        exportState = .initial
                        selectedProfileId = nil
                        exportMessage = nil
                    }
                )
            case .selectingScope:
                 BookSelectionView(
                     notesManager: notesManager,
                     selectedBook: $selectedBook,
                     showAllBooks: true,
                     isEnabled: true,
                     onConfirm: {
                         if let profileId = selectedProfileId {
                             let scope: NotesManager.ExportScope = selectedBook == "All Books" ? .all : .specificBook
                             exportMessage = "Exporting \(notesManager.profiles.first(where: {$0.id == profileId})?.name ?? "") (\(selectedBook))..."
                             notesManager.exportProfile(id: profileId, scope: scope) { url in
                                 if let url = url {
                                     selectedFileURL = url
                                     isShareSheetPresented = true
                                     exportMessage = "Export successful. Ready to share."
                                 } else {
                                     exportMessage = "Export failed. Please try again."
                                 }
                                 exportState = .initial
                                 selectedProfileId = nil
                                 self.selectedBook = "All Books"
                             }
                         }
                     },
                     onCancel: {
                         exportState = .nodeSelected
                         self.selectedBook = "All Books"
                         exportMessage = "Scope selection cancelled."
                     }
                 )
            default:
                VStack(spacing: 15) {
                    Button(selectedProfileId == nil ? "Select Scripture Node" : "Node: \(truncateText(notesManager.profiles.first(where: { $0.id == selectedProfileId })?.name ?? "Error"))") {
                        exportState = .selectingNode
                        exportMessage = nil
                    }
                    .buttonStyle(ArchivumButtonStyle(themeManager: themeManager))

                    Button("Select Export Scope (\(selectedBook))") {
                        exportState = .selectingScope
                        exportMessage = nil
                    }
                    .buttonStyle(ArchivumButtonStyle(themeManager: themeManager))
                    .disabled(selectedProfileId == nil)
                    
                    if let message = exportMessage {
                        Text(message)
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                            .padding(.top, 5)
                    }
                }
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let url = selectedFileURL {
                ActivityView(activityItems: [url], applicationActivities: nil, excludedActivityTypes: nil, completionWithItemsHandler: { (_, _, _, error) in
                    Task { @MainActor in
                        self.exportMessage = "Share sheet dismissed."
                        if let error = error {
                            self.exportMessage = "Share operation failed: \(error.localizedDescription)"
                        }
                        self.selectedFileURL = nil
                    }
                })
            }
        }
    }
    private func truncateText(_ text: String, maxLength: Int = 15) -> String {
        if text.count > maxLength { return String(text.prefix(maxLength - 3)) + "..." }
        return text
    }
}

// MARK: - Codex Export View
struct CodexExportView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @State private var exportState: ExportState = .initial
    @State private var isShareSheetPresented: Bool = false
    @State private var selectedFileURL: URL?
    @State private var selectedProfileId: UUID?
    @State private var exportMessage: String?

    enum ExportState { case initial, selectingNode }

    init(notesManager: NotesManager) {
        self.notesManager = notesManager
    }

    var body: some View {
        Group {
            switch exportState {
            case .selectingNode:
                ExportProfileSelectionView(
                    notesManager: notesManager,
                    dataMode: ContentView.DataMode.codex,
                    onSelect: { profileId in
                        self.selectedProfileId = profileId
                        guard let profile = notesManager.profiles.first(where: { $0.id == profileId }) else {
                            exportMessage = "Selected profile not found."
                            exportState = .initial
                            return
                        }
                        exportMessage = "Exporting Codex Node '\(profile.name)'..."
                        notesManager.exportProfile(id: profileId, scope: .all) { url in
                            if let url = url {
                                selectedFileURL = url
                                isShareSheetPresented = true
                                exportMessage = "Codex '\(profile.name)' exported."
                            } else {
                                exportMessage = "Codex export failed for '\(profile.name)'."
                            }
                            exportState = .initial
                            self.selectedProfileId = nil
                        }
                    },
                    onCancel: {
                        exportState = .initial
                        exportMessage = "Export cancelled."
                        self.selectedProfileId = nil
                    }
                )
            default:
                VStack(spacing: 15) {
                    Button("Select Codex Node to Export") { exportState = .selectingNode; exportMessage = nil }
                        .buttonStyle(ArchivumButtonStyle(themeManager: themeManager))
                    if let message = exportMessage {
                        Text(message)
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                            .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity)).padding(.top, 5)
                    }
                }
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let url = selectedFileURL {
                ActivityView(activityItems: [url], applicationActivities: nil, excludedActivityTypes: nil, completionWithItemsHandler: { (_, _, _, error) in
                     Task { @MainActor in
                        self.exportMessage = "Share sheet dismissed."
                        if let error = error { self.exportMessage = "Share operation failed: \(error.localizedDescription)" }
                        self.selectedFileURL = nil
                    }
                })
            }
        }
    }
}

// MARK: - Scripture Import View
struct ScriptureImportView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @State private var importState: ImportState = .initial
    @State private var selectedFileURL: URL?
    @State private var importNodeName: String = ""
    @State private var isDocumentPickerPresented: Bool = false
    @State private var importMessage: String?
    @State private var isImporting: Bool = false

    enum ImportState { case initial, fileSelected, selectingNodeToMerge, namingFreshNode }

    init(notesManager: NotesManager) {
        self.notesManager = notesManager
    }

    var body: some View {
        VStack(spacing: 15) {
            if isImporting {
                ProgressView()
                if let msg = importMessage { Text(msg).font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12))).padding(.top, 5) }
            } else {
                Button(selectedFileURL == nil ? "Select Scripture Archive" : "File: \(truncateText(selectedFileURL?.lastPathComponent ?? "Error"))") {
                    if importState != .fileSelected { isDocumentPickerPresented = true; importMessage = nil }
                }
                .buttonStyle(ArchivumButtonStyle(themeManager: themeManager)).padding(.bottom, 10)

                if selectedFileURL != nil {
                    if importState == .fileSelected {
                        Text("Archive Selected: \(selectedFileURL?.lastPathComponent ?? "")")
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12))).padding(.bottom, 5)
                        Button("Merge with Existing Scripture Node") {
                            importState = .selectingNodeToMerge
                            importMessage = "Select a Scripture Node to merge into."
                        }.buttonStyle(ArchivumButtonStyle(themeManager: themeManager))
                        Button("Import as Fresh Scripture Node") {
                            importState = .namingFreshNode
                            importNodeName = selectedFileURL?.deletingPathExtension().lastPathComponent ?? "New Scripture Node"
                            importMessage = "Enter a name for the new Scripture Node."
                        }.buttonStyle(ArchivumButtonStyle(themeManager: themeManager))
                        Button("Cancel File Selection") {
                            selectedFileURL = nil; importState = .initial; importMessage = nil
                        }.buttonStyle(ArchivumButtonStyle(themeManager: themeManager, foregroundColor: .red.opacity(0.7))).padding(.top, 10)
                    }
                }
                
                if importState == .selectingNodeToMerge {
                    Text("Choose Scripture Node to Merge With:").font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    ExportProfileSelectionView(
                        notesManager: notesManager,
                        dataMode: ContentView.DataMode.scripture,
                        onSelect: { profileId in
                            guard let url = selectedFileURL else {
                                Task { @MainActor in importMessage = "Error: File URL is missing."; importState = .fileSelected }
                                return
                            }
                            Task { @MainActor in isImporting = true; importMessage = "Merging notes..." }
                            notesManager.mergeImportedProfile(from: url, into: profileId) { success, error in
                                self.isImporting = false
                                if success {
                                    self.importMessage = "Successfully merged notes into '\(notesManager.profiles.first(where: {$0.id == profileId})?.name ?? "")'."
                                } else {
                                    self.importMessage = "Merge failed: \(error ?? "Unknown error")"
                                }
                                self.selectedFileURL = nil
                                self.importState = .initial
                            }
                        },
                        onCancel: { Task { @MainActor in importState = .fileSelected; importMessage = "Merge cancelled. Choose an action." } }
                    )
                }

                if importState == .namingFreshNode {
                     Text("Name for New Scripture Node:").font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    ImportNameEntryView(
                        notesManager: notesManager,
                        importProfileName: $importNodeName,
                        fileURL: selectedFileURL,
                        dataMode: ContentView.DataMode.scripture,
                        onConfirm: { name in
                            guard let url = selectedFileURL, !name.isEmpty else {
                                Task { @MainActor in
                                    importMessage = name.isEmpty ? "Node name cannot be empty." : "Error: File URL is missing."
                                    if !name.isEmpty { importState = .fileSelected }
                                }
                                return
                            }
                            Task { @MainActor in isImporting = true; importMessage = "Importing as new node '\(name)'..." }
                            notesManager.importProfile(from: url, name: name) { success, error in
                                self.isImporting = false
                                if success {
                                    self.importMessage = "Successfully imported '\(name)'."
                                } else {
                                    self.importMessage = "Import failed for '\(name)': \(error ?? "Unknown error")"
                                }
                                self.selectedFileURL = nil
                                self.importState = .initial
                                self.importNodeName = ""
                            }
                        },
                        onCancel: { Task { @MainActor in importState = .fileSelected; importNodeName = ""; importMessage = "Import as fresh node cancelled." } }
                    )
                }
                
                if !isImporting, let message = importMessage, importState == .initial || importState == .fileSelected {
                     Text(message).font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity)).padding(.top, 10)
                }
            }
        }
        .sheet(isPresented: $isDocumentPickerPresented) {
            DocumentPicker(contentTypes: [UTType.json, UTType.text], onPick: { url in
                Task { @MainActor in
                    selectedFileURL = url
                    importState = .fileSelected
                    importMessage = "File '\(url.lastPathComponent)' selected. Choose import action."
                }
            }, onCancel: nil)
        }
    }
    private func truncateText(_ text: String, maxLength: Int = 20) -> String {
        if text.count > maxLength { return String(text.prefix(maxLength - 3)) + "..." }
        return text
    }
}

// MARK: - Codex Import View
struct CodexImportView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @State private var importState: ImportState = .initial
    @State private var selectedFileURL: URL?
    @State private var importNodeName: String = ""
    @State private var isDocumentPickerPresented: Bool = false
    @State private var importMessage: String?
    @State private var isImporting: Bool = false

    enum ImportState { case initial, fileSelected, namingNode }

    init(notesManager: NotesManager) {
        self.notesManager = notesManager
    }

    var body: some View {
        VStack(spacing: 15) {
            if isImporting {
                ProgressView()
                if let msg = importMessage { Text(msg).font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12))).padding(.top, 5) }
            } else {
                Button(selectedFileURL == nil ? "Select Codex File (JSON, TXT, EPUB)" : "File: \(truncateText(selectedFileURL?.lastPathComponent ?? "Error"))") {
                    isDocumentPickerPresented = true; importMessage = nil
                }
                .buttonStyle(ArchivumButtonStyle(themeManager: themeManager)).padding(.bottom, 10)

                if selectedFileURL != nil {
                     if importState == .fileSelected {
                        Text("File Selected: \(selectedFileURL?.lastPathComponent ?? "")")
                            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12))).padding(.bottom, 5)
                        Button("Proceed to Name Codex Node") {
                            importState = .namingNode
                            importNodeName = selectedFileURL?.deletingPathExtension().lastPathComponent ?? "New Codex"
                            importMessage = "Enter a name for the new Codex Node."
                        }.buttonStyle(ArchivumButtonStyle(themeManager: themeManager))
                        Button("Cancel File Selection") {
                            selectedFileURL = nil; importState = .initial; importMessage = nil
                        }.buttonStyle(ArchivumButtonStyle(themeManager: themeManager, foregroundColor: .red.opacity(0.7))).padding(.top, 10)
                    }
                }

                if importState == .namingNode {
                    Text("Name for New Codex Node:").font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    ImportNameEntryView(
                        notesManager: notesManager,
                        importProfileName: $importNodeName,
                        fileURL: selectedFileURL,
                        dataMode: ContentView.DataMode.codex,
                        onConfirm: { name in
                            guard let url = selectedFileURL, !name.isEmpty else {
                                Task { @MainActor in
                                    importMessage = name.isEmpty ? "Codex name cannot be empty." : "Error: File URL is missing."
                                    if !name.isEmpty { importState = .fileSelected }
                                }
                                return
                            }
                            Task { @MainActor in
                                self.isImporting = true
                                self.importMessage = "Inscribing Codex '\(name)'... this may take a moment."
                            }
                            notesManager.codexManager.importDocument(from: url, title: name) { success, error in
                                Task { @MainActor in self.isImporting = false }
                                if success {
                                    Task { @MainActor in self.importMessage = "Codex '\(name)' successfully inscribed." }
                                    Task {
                                        var newCodexDocId: UUID? = nil
                                        await MainActor.run { // Ensure access to notesManager is on main actor
                                            if let newDoc = notesManager.codexManager.documents.first(where: { $0.title == name }) {
                                                if let _ = notesManager.codexManager.getDocument(id: newDoc.id) {
                                                    newCodexDocId = newDoc.id
                                                }
                                            }
                                        }
                                        await notesManager.createProfile(name: name, nodeType: .codex, codexDocumentId: newCodexDocId)
                                        if newCodexDocId == nil {
                                            print("Warning: Could not reliably find newly imported Codex doc by title to link profile ID.")
                                        }
                                    }
                                } else {
                                     Task { @MainActor in self.importMessage = "Failed to inscribe Codex '\(name)': \(error ?? "Unknown error")" }
                                }
                                Task { @MainActor in
                                    self.selectedFileURL = nil
                                    self.importState = .initial
                                    self.importNodeName = ""
                                }
                            }
                        },
                        onCancel: { Task { @MainActor in importState = .fileSelected; importNodeName = ""; importMessage = "Codex import cancelled." } }
                    )
                }
                
                if !isImporting, let message = importMessage, importState == .initial || importState == .fileSelected {
                     Text(message).font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity)).padding(.top, 10)
                }
            }
        }
        .sheet(isPresented: $isDocumentPickerPresented) {
            DocumentPicker(contentTypes: [UTType.json, UTType.plainText, UTType.epub], onPick: { url in
                 Task { @MainActor in
                    selectedFileURL = url
                    importState = .fileSelected
                    importMessage = "File '\(url.lastPathComponent)' selected. Proceed to name the Codex."
                }
            }, onCancel: nil)
        }
    }
    private func truncateText(_ text: String, maxLength: Int = 20) -> String {
        if text.count > maxLength { return String(text.prefix(maxLength - 3)) + "..." }
        return text
    }
}

// MARK: - Shared Supporting Views

struct ArchivumButtonStyle: ButtonStyle {
    @ObservedObject var themeManager: ThemeManager
    var foregroundColor: Color?

    init(themeManager: ThemeManager, foregroundColor: Color? = nil) {
        self.themeManager = themeManager
        self.foregroundColor = foregroundColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 12)))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(minWidth: 160, idealHeight: 35)
            .foregroundColor(foregroundColor ?? themeManager.themeColor.opacity(themeManager.fontOpacity))
            .background(themeManager.backgroundColor)
            .overlay(
                Rectangle()
                    .stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct ExportProfileSelectionView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    let dataMode: ContentView.DataMode
    let onSelect: (UUID) -> Void
    let onCancel: () -> Void

    init(notesManager: NotesManager, dataMode: ContentView.DataMode, onSelect: @escaping (UUID) -> Void, onCancel: @escaping () -> Void) {
        self.notesManager = notesManager
        self.dataMode = dataMode
        self.onSelect = onSelect
        self.onCancel = onCancel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Select \(dataMode == .scripture ? "Scripture" : "Codex") Node")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 16)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding([.top, .horizontal], 10)

                let filteredProfiles = notesManager.profiles.filter { $0.nodeType == (dataMode == .scripture ? .scripture : .codex) }

                if filteredProfiles.isEmpty {
                    Text("No \(dataMode == .scripture ? "Scripture" : "Codex") Nodes Available.")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity * 0.7))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(filteredProfiles) { profile in
                        Button(action: { onSelect(profile.id) }) {
                            Text(profile.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(ArchivumButtonStyle(themeManager: themeManager))
                        .padding(.horizontal, 10)
                    }
                }
                Divider().padding(.vertical, 5)
                Button("[Annul Task]") { onCancel() }
                    .buttonStyle(ArchivumButtonStyle(themeManager: themeManager, foregroundColor: .orange))
                    .padding([.horizontal, .bottom], 10)
            }
            .padding(.vertical, 10)
        }
        .background(themeManager.backgroundColor)
        .frame(maxHeight: 300)
    }
}

struct ImportNameEntryView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var notesManager: NotesManager
    @Binding var importProfileName: String
    let fileURL: URL?
    let dataMode: ContentView.DataMode
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool

    init(notesManager: NotesManager, importProfileName: Binding<String>, fileURL: URL?, dataMode: ContentView.DataMode, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.notesManager = notesManager
        self._importProfileName = importProfileName
        self.fileURL = fileURL
        self.dataMode = dataMode
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Assign Name for \(dataMode == .scripture ? "Scripture" : "Codex") Node")
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 16)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(.bottom, 5)

                if let fileName = fileURL?.lastPathComponent {
                    Text("Original file: \(fileName)")
                        .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 10)))
                        .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity * 0.7))
                }

                TextField("Node Name", text: $importProfileName)
                    .font(.custom(themeManager.selectedFont, size: themeManager.adjustedFontSize(base: 14)))
                    .foregroundColor(themeManager.themeColor.opacity(themeManager.fontOpacity))
                    .padding(10)
                    .background(themeManager.backgroundColor.opacity(0.5))
                    .overlay(Rectangle().stroke(themeManager.lineStroke, lineWidth: themeManager.lineWidth))
                    .focused($isTextFieldFocused)
                    .onAppear {
                        if importProfileName.isEmpty {
                            importProfileName = fileURL?.deletingPathExtension().lastPathComponent ?? ""
                        }
                        isTextFieldFocused = true
                    }
                
                HStack(spacing: 10) {
                    Button("[Affirm Order]") {
                        if !importProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onConfirm(importProfileName.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    }
                    .buttonStyle(ArchivumButtonStyle(themeManager: themeManager))
                    .disabled(importProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("[Annul Task]") { onCancel() }
                     .buttonStyle(ArchivumButtonStyle(themeManager: themeManager, foregroundColor: .orange))
                }
                .padding(.top, 10)
            }
            .padding(15)
        }
        .background(themeManager.backgroundColor)
        .frame(maxHeight: 300)
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var contentTypes: [UTType]
    let onPick: (URL) -> Void
    var onCancel: (() -> Void)?

    init(contentTypes: [UTType], onPick: @escaping (URL) -> Void, onCancel: (() -> Void)? = nil) {
        self.contentTypes = contentTypes
        self.onPick = onPick
        self.onCancel = onCancel
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self) // Error was here: /Users/ivanestrada/Desktop/projects/archivumcurrentgemini/Archivum/Views/DataView.swift:647:57
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { parent.onPick(url) }
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel?()
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]?
    var excludedActivityTypes: [UIActivity.ActivityType]?
    var completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler?

    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil, excludedActivityTypes: [UIActivity.ActivityType]? = nil, completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
        self.completionWithItemsHandler = completionWithItemsHandler
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = completionWithItemsHandler
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - DataView_Previews
struct DataView_Previews: PreviewProvider {
    static var previews: some View {
        let themeManager = ThemeManager()
        let notesManager = NotesManager()
        
        return DataView(notesManager: notesManager, dataMode: .constant(ContentView.DataMode.scripture))
            .environmentObject(themeManager)
            .onAppear {
                if notesManager.profiles.isEmpty {
                    Task {
                        await notesManager.createProfile(name: "Preview Scripture", nodeType: .scripture)
                    }
                }
            }
    }
}
