// DatabaseModels.swift
import Foundation
import GRDB

// Profile Record for Database (remains Sendable)
struct DBProfile: Identifiable, Codable, FetchableRecord, PersistableRecord, Sendable {
    var id: UUID
    var name: String
    var nodeType: Profile.NodeType
    var scriptureVersion: String?
    var codexDocumentId: UUID?
    static let databaseTableName = "dbProfile"
}

// NoteEntry Record for Database (remains Sendable, add reverse association for hashtags)
struct DBNoteEntry: Identifiable, Codable, FetchableRecord, PersistableRecord, Sendable {
    var id: UUID
    var profileId: UUID
    var verseReference: String
    var text: String
    var timestamp: Date
    static let databaseTableName = "dbNoteEntry"

    static let profile = belongsTo(DBProfile.self)
    // For joining DBNoteEntry with DBHashtag through DBNoteHashtag
    static let hashtags = hasMany(DBHashtag.self, through: hasMany(DBNoteHashtag.self), using: DBNoteHashtag.hashtag)
}

// Hashtag Record (remains Sendable, add reverse association for notes)
struct DBHashtag: Identifiable, Codable, FetchableRecord, PersistableRecord, Sendable {
    var id: UUID
    var tagName: String
    static let databaseTableName = "dbHashtag"

    static func filter(tagName: String) -> QueryInterfaceRequest<DBHashtag> {
        DBHashtag.filter(Column("tagName") == tagName.lowercased())
    }
    // For joining DBHashtag with DBNoteEntry through DBNoteHashtag
    static let noteEntries = hasMany(DBNoteEntry.self, through: hasMany(DBNoteHashtag.self), using: DBNoteHashtag.noteEntry)
}

// NoteHashtag Junction Table Record (remains Sendable)
struct DBNoteHashtag: Codable, FetchableRecord, PersistableRecord, Sendable {
    var noteEntryId: UUID
    var hashtagId: UUID
    static let databaseTableName = "dbNoteHashtag"

    // Associations from the junction table to the main tables
    static let noteEntry = belongsTo(DBNoteEntry.self) // GRDB can infer key if named conventionally (noteEntryId)
    static let hashtag = belongsTo(DBHashtag.self)   // GRDB can infer key if named conventionally (hashtagId)
}

// Ensure Profile.NodeType in Profile.swift is Sendable
