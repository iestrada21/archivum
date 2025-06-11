import Foundation
import GRDB

actor DatabaseManager {
    static let shared = DatabaseManager()
    private var dbQueue: DatabaseQueue

    private init() { //
        do {
            let fileManager = FileManager.default //
            let dbURL = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) //
                .appendingPathComponent("archivum.sqlite") //
            
            print("Database URL: \(dbURL.path)") //
            dbQueue = try DatabaseQueue(path: dbURL.path) //
            
            // MODIFIED: Dispatch the actor-isolated call to a Task
            Task {
                do {
                    try await self.setupDatabaseSchema()
                } catch {
                    // This error occurs in a detached Task.
                    // Logging it is important. fatalError here will terminate the app.
                    print("CRITICAL: Failed to setup database schema from init Task: \(error.localizedDescription)")
                    // Depending on your app's resilience strategy, you might set a flag
                    // or attempt recovery, but for a critical component like DB schema,
                    // fatalError might be appropriate if the app cannot run without it.
                    fatalError("Failed to setup database schema from init Task: \(error.localizedDescription)")
                }
            }
        } catch { // This catch is for dbURL and dbQueue initialization errors
            fatalError("Failed to initialize database infrastructure: \(error.localizedDescription)") //
        }
    }

    // This method is an instance method of the actor, so it's actor-isolated.
    // It can be called with 'await self.setupDatabaseSchema()' from within the Task in init.
    private func setupDatabaseSchema() throws { //
        try dbQueue.write { database in //
            try database.create(table: DBProfile.databaseTableName, ifNotExists: true) { t in //
                t.column("id", .text).primaryKey() //
                t.column("name", .text).notNull() //
                t.column("nodeType", .text).notNull() //
                t.column("scriptureVersion", .text) //
                t.column("codexDocumentId", .text) //
            }
            try database.create(table: DBNoteEntry.databaseTableName, ifNotExists: true) { t in //
                t.column("id", .text).primaryKey() //
                t.column("profileId", .text).notNull().indexed().references(DBProfile.databaseTableName, onDelete: .cascade) //
                t.column("verseReference", .text).notNull().indexed() //
                t.column("text", .text).notNull() //
                t.column("timestamp", .datetime).notNull() //
            }
            try database.create(table: DBHashtag.databaseTableName, ifNotExists: true) { t in //
                t.column("id", .text).primaryKey() //
                t.column("tagName", .text).notNull().unique(onConflict: .ignore).indexed() //
            }
            try database.create(table: DBNoteHashtag.databaseTableName, ifNotExists: true) { t in //
                t.column("noteEntryId", .text).notNull().references(DBNoteEntry.databaseTableName, onDelete: .cascade) //
                t.column("hashtagId", .text).notNull().references(DBHashtag.databaseTableName, onDelete: .cascade) //
                t.primaryKey(["noteEntryId", "hashtagId"], onConflict: .ignore) //
            }
            print("Database schema set up successfully.") //
        }
    }

    // MARK: - Profile CRUD
    func saveProfile(_ profile: DBProfile) throws { //
        try dbQueue.write { db in try profile.save(db) } //
    }

    func fetchProfiles() throws -> [DBProfile] { //
        try dbQueue.read { db in try DBProfile.fetchAll(db) } //
    }
    
    func fetchProfile(id: UUID) throws -> DBProfile? { //
        try dbQueue.read { db in try DBProfile.fetchOne(db, key: id) } //
    }

    func deleteProfile(id: UUID) throws { //
        try dbQueue.write { db in
            _ = try DBProfile.deleteOne(db, key: id) //
            _ = try DBNoteEntry.filter(Column("profileId") == id).deleteAll(db) //
        }
    }
    
    func updateProfileName(id: UUID, newName: String) throws { //
        try dbQueue.write { db in
            if var profile = try DBProfile.fetchOne(db, key: id) { //
                profile.name = newName //
                try profile.save(db) //
            }
        }
    }

    // MARK: - NoteEntry CRUD
    func saveNoteEntry(_ noteEntry: DBNoteEntry) throws { //
        try dbQueue.write { db in try noteEntry.save(db) } //
    }
    
    func saveNotesForProfile(profileId: UUID, notesDict: [String: [Profile.NoteEntry]]) throws { //
        let dbNoteEntries = notesDict.flatMap { verseRef, noteEntriesArray -> [DBNoteEntry] in //
            noteEntriesArray.map { appNote in //
                DBNoteEntry(id: appNote.id, profileId: profileId, verseReference: verseRef, //
                            text: appNote.text, timestamp: appNote.timestamp) //
            }
        }
        try dbQueue.write { db in //
            for entry in dbNoteEntries { try entry.save(db) } //
        }
    }

    func fetchNoteEntries(profileId: UUID) throws -> [DBNoteEntry] { //
        try dbQueue.read { db in //
            try DBNoteEntry.filter(Column("profileId") == profileId) //
                           .order(Column("timestamp").asc) // Using Column("timestamp") //
                           .fetchAll(db) //
        }
    }
    
    func fetchNoteEntries(profileId: UUID, verseRef: String) throws -> [DBNoteEntry] { //
        try dbQueue.read { db in //
            try DBNoteEntry.filter(Column("profileId") == profileId && Column("verseReference") == verseRef) //
                           .order(Column("timestamp").asc) // Using Column("timestamp") //
                           .fetchAll(db) //
        }
    }

    func deleteNoteEntry(id: UUID) throws { //
        try dbQueue.write { db in //
            _ = try DBNoteEntry.deleteOne(db, key: id) //
            _ = try DBNoteHashtag.filter(Column("noteEntryId") == id).deleteAll(db) //
        }
    }
    
    func updateNoteEntry(_ noteEntry: DBNoteEntry) throws { //
        try dbQueue.write { db in try noteEntry.save(db) } //
    }

    // MARK: - Hashtag CRUD & Linking
    func fetchOrCreateHashtag(tagName: String) throws -> DBHashtag { //
        let normalizedTag = tagName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) //
        return try dbQueue.inDatabase { db in //
            if let existingTag = try DBHashtag.filter(Column("tagName") == normalizedTag).fetchOne(db) { //
                return existingTag //
            } else { //
                let newTag = DBHashtag(id: UUID(), tagName: normalizedTag) //
                try newTag.save(db) //
                return newTag //
            }
        }
    }

    func linkNote(_ noteEntryId: UUID, toHashtag hashtagId: UUID) throws { //
        let link = DBNoteHashtag(noteEntryId: noteEntryId, hashtagId: hashtagId) //
        try dbQueue.write { db in try link.save(db) } //
    }
    
    func unlinkNote(_ noteEntryId: UUID, fromHashtag hashtagId: UUID) throws { //
        try dbQueue.write { db in //
            _ = try DBNoteHashtag.filter(Column("noteEntryId") == noteEntryId && Column("hashtagId") == hashtagId).deleteAll(db) //
        }
    }

    func fetchHashtagsForNote(_ noteEntryId: UUID) throws -> [DBHashtag] { //
        try dbQueue.read { db in //
            guard let noteEntry = try DBNoteEntry.fetchOne(db, key: noteEntryId) else { //
                return [] //
            }
            return try noteEntry.request(for: DBNoteEntry.hashtags).fetchAll(db) //
        }
    }
    
    func fetchNoteEntriesForHashtag(_ hashtagId: UUID, profileId: UUID? = nil) throws -> [DBNoteEntry] { //
        try dbQueue.read { db in //
            guard let hashtag = try DBHashtag.fetchOne(db, key: hashtagId) else { //
                return [] //
            }
            var request = hashtag.request(for: DBHashtag.noteEntries) // Request for DBNoteEntry //
            if let pId = profileId { //
                request = request.filter(Column("profileId") == pId) // Use Column("profileId") //
            }
            return try request.order(Column("timestamp").desc).fetchAll(db) // Use Column("timestamp") //
        }
    }
    
    // MARK: - Search
    func searchNoteEntries(query: String, profileId: UUID? = nil) throws -> [DBNoteEntry] { //
        let pattern = "%\(query.lowercased())%" //
        return try dbQueue.read { db in //
            var request = DBNoteEntry.filter(sql: "LOWER(text) LIKE ?", arguments: [pattern]) //
            if let pId = profileId { //
                request = request.filter(Column("profileId") == pId) //
            }
            return try request.order(Column("timestamp").desc).fetchAll(db) // Use Column("timestamp") //
        }
    }
    
    // MARK: - Migration
    func migrateUserDefaultsToDB(profilesFromUserDefaults: [Profile]) throws { //
        let profilesInDB = try self.fetchProfiles() //
        guard profilesInDB.isEmpty else { //
            print("Database already contains profiles. Skipping migration.") //
            return //
        }
        print("Starting migration of UserDefaults to SQLite DB...") //
        for appProfile in profilesFromUserDefaults { //
            let dbProfile = DBProfile(id: appProfile.id, name: appProfile.name, //
                                   nodeType: appProfile.nodeType, scriptureVersion: appProfile.scriptureVersion, //
                                    codexDocumentId: appProfile.codexDocumentId) //
            try self.saveProfile(dbProfile) //

            for (verseRef, noteEntriesArray) in appProfile.notes { //
                for appNoteEntry in noteEntriesArray { //
                    let dbNote = DBNoteEntry(id: appNoteEntry.id, // Assumes appNoteEntry.id is valid //
                                            profileId: appProfile.id, verseReference: verseRef, //
                                            text: appNoteEntry.text, timestamp: appNoteEntry.timestamp) //
                    try self.saveNoteEntry(dbNote) //
                }
            }
        }
        print("Migration completed.") //
    }
}
