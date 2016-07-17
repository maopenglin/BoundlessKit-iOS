//
//  DopeStorage.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation
//import SQLite



enum SQLiteError: ErrorType {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

/** tbc
 
 
 
 
*/


internal class SQLStorage : NSObject{
    
//    private let dbPointer: COpaquePointer
//    
//    private init(dbPointer: COpaquePointer) {
//        self.dbPointer = dbPointer
//    }
//    
//    deinit {
//        sqlite3_close(dbPointer)
//    }
//    
//    static func open(path: String) throws -> SQLiteDatabase {
//        var db: COpaquePointer = nil
//        // 1
//        if sqlite3_open(path, &db) == SQLITE_OK {
//            // 2
//            return SQLiteDatabase(dbPointer: db)
//        } else {
//            // 3
//            defer {
//                if db != nil {
//                    sqlite3_close(db)
//                }
//            }
//            
//            if let message = String.fromCString(sqlite3_errmsg(db)) {
//                throw SQLiteError.OpenDatabase(message: message)
//            } else {
//                throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
//            }
//        }
//    }
//    
//    private var errorMessage: String {
//        if let errorMessage = String.fromCString(sqlite3_errmsg(dbPointer)) {
//            return errorMessage
//        } else {
//            return "No error message provided from sqlite."
//        }
//    }
    
    
    static let instance: SQLStorage = SQLStorage()
    private override init() {
        super.init()
    }
    
    
    static func writeTrack(event: DopeEvent){
        
    }
    
    static func writeReinforcement(event: DopeEvent){
        
    }
    
    
}