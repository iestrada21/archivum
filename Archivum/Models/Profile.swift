//
//  Profile.swift
//  Archivum
//
//  Created by Ivan Estrada on 4/26/25.
//

import Foundation

struct Profile: Identifiable, Codable, Equatable {
    var id: UUID // Already Identifiable, UUID() default removed to ensure it's set at creation
    var name: String
    var nodeType: NodeType
    var scriptureVersion: String?
    var codexDocumentId: UUID?
    var notes: [String: [NoteEntry]] // Key: VerseReference, Value: Array of notes

    enum NodeType: String, Codable, Equatable, Sendable {
        case scripture
        case codex
    }

    // Modified NoteEntry to be Identifiable and have an 'id'
    struct NoteEntry: Codable, Equatable, Identifiable {
        var id: UUID // Added for Identifiable conformance and DB linking
        var text: String
        var timestamp: Date

        // Initializer to ensure 'id' is always present
        init(id: UUID = UUID(), text: String, timestamp: Date) {
            self.id = id
            self.text = text
            self.timestamp = timestamp
        }

        // Custom Equatable, if needed, though Swift synthesizes for simple types
        // If you only care about content for equality and not ID/timestamp for some comparisons:
        // static func == (lhs: NoteEntry, rhs: NoteEntry) -> Bool {
        //     return lhs.text == rhs.text // Example: content-based equality
        // }
        // For general Equatable conformance including id and timestamp, Swift's synthesis is usually fine.
        // The existing == was fine too, but with 'id' it would be:
         static func == (lhs: NoteEntry, rhs: NoteEntry) -> Bool {
             return lhs.id == rhs.id &&
                    lhs.text == rhs.text &&
                    lhs.timestamp == rhs.timestamp
         }
    }

    // Explicit CodingKeys might be needed if 'id' in NoteEntry was optional before
    // or if JSON keys differ, but for now, assume standard encoding.
    // enum CodingKeys: String, CodingKey {
    //     case id
    //     case name
    //     case nodeType
    //     case scriptureVersion
    //     case codexDocumentId
    //     case notes
    // }

    // Initializer to ensure 'id' for Profile is set (if not using default UUID())
    init(id: UUID = UUID(), name: String, nodeType: NodeType, scriptureVersion: String? = nil, codexDocumentId: UUID? = nil, notes: [String: [NoteEntry]] = [:]) {
        self.id = id
        self.name = name
        self.nodeType = nodeType
        self.scriptureVersion = scriptureVersion
        self.codexDocumentId = codexDocumentId
        self.notes = notes
    }


    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.nodeType == rhs.nodeType &&
               lhs.scriptureVersion == rhs.scriptureVersion &&
               lhs.codexDocumentId == rhs.codexDocumentId &&
               lhs.notes == rhs.notes // This requires NoteEntry to be Equatable
    }
}
