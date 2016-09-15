//
//  DopeStorage.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation
// import SQLite

enum SQLDataAccessError: Error {
    case datastore_Connection_Error
    case insert_Error
    case delete_Error
    case search_Error
    case nil_In_Data
}

open class SQLiteDataStore : NSObject{
    
    static let sharedInstance: SQLiteDataStore = SQLiteDataStore()
    
//    let DDB: Connection?
    
    /// Creates a SQLite database and tables for DopamineKit
    ///
    fileprivate override init() {
//        var path = "DopamineDB.sqlite"
//        if let dirs: [NSString] = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true) as [NSString] {
//            let dir = dirs[0]
//            path = dir.appendingPathComponent(path);
//            DopamineKit.DebugLog("DopamineKit SQLite db path:\(path)")
//        }
//        
//        do {
//            DDB = try Connection(path)
//        } catch _ {
//            DopamineKit.DebugLog("Connection to \(path) failed")
//            DDB = nil
//        }
//        
//        super.init()
//        
//        createTables()
    }
    
    /// Creates all the tables needed for DopamineKit
    ///
    func createTables(){
//        guard let _ = DDB else {
//            DopamineKit.DebugLog("No connection to SQLite")
//            return
//        }
//        
//        SQLTrackedActionDataHelper.createTable()
//        SQLReportedActionDataHelper.createTable()
//        SQLCartridgeDataHelper.createTable()
    }
    
    /// Drops all tables used in DopamineKit
    ///
    func dropTables(){
//        guard let _ = DDB else {
//            DopamineKit.DebugLog("No connection to SQLite")
//            return
//        }
//        
//        SQLTrackedActionDataHelper.dropTable()
//        SQLReportedActionDataHelper.dropTable()
//        SQLCartridgeDataHelper.dropTable()
    }
    
    /// Drops and the Creates all tables
    ///
    open func clearTables() {
//        dropTables()
//        createTables()
    }
    
}
