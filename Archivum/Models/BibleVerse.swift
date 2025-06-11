//
//  BibleVerse.swift
//  Archivum
//
//  Created by Ivan Estrada on 4/26/25.
//

import Foundation

struct BibleVerse: Identifiable {
    let id = UUID()
    let reference: String // e.g., "Genesis 1:1"
    let book: String
    let chapter: Int
    let verse: Int
    let text: String
}
