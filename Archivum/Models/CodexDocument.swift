//
//  CodexDocument.swift
//  Archivum
//
//  Created by Ivan Estrada on 5/1/25.
//

import Foundation

struct CodexDocument: Identifiable, Codable, Sendable {
    let id: UUID
    var title: String // Changed from let to var to allow renaming
    let chapters: [Chapter]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case chapters
    }
}

struct Chapter: Codable, Equatable, Sendable {
    let number: Int
    let verses: [Verse]
}

struct Verse: Codable, Equatable, Sendable {
    let number: Int
    let text: String
}
