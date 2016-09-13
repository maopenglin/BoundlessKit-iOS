//
//  DopeStorage.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation
import SQLite

enum SQLDataAccessError: ErrorType {
    case Datastore_Connection_Error
    case Insert_Error
    case Delete_Error
    case Search_Error
    case Nil_In_Data
}

public class SQLiteDataStore : NSObject{
    
    static let sharedInstance: SQLiteDataStore = SQLiteDataStore()
    
    let DDB: Connection?
    
    /// Creates a SQLite database and tables for DopamineKit
    ///
    private override init() {
        var path = "DopamineDB.sqlite"
        if let dirs: [NSString] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as [NSString] {
            let dir = dirs[0]
            path = dir.stringByAppendingPathComponent(path);
            DopamineKit.DebugLog("DopamineKit SQLite db path:\(path)")
        }
        
        do {
            DDB = try Connection(path)
        } catch _ {
            DopamineKit.DebugLog("Connection to \(path) failed")
            DDB = nil
        }
        
        super.init()
        
        createTables()
    }
    
    /// Creates all the tables needed for DopamineKit
    ///
    func createTables(){
        guard let _ = DDB else {
            DopamineKit.DebugLog("No connection to SQLite")
            return
        }
        
        SQLTrackedActionDataHelper.createTable()
        SQLReportedActionDataHelper.createTable()
        SQLCartridgeDataHelper.createTable()
        SQLSyncOverviewDataHelper.createTable()
    }
    
    /// Drops all tables used in DopamineKit
    ///
    func dropTables(){
        guard let _ = DDB else {
            DopamineKit.DebugLog("No connection to SQLite")
            return
        }
        
        SQLTrackedActionDataHelper.dropTable()
        SQLReportedActionDataHelper.dropTable()
        SQLCartridgeDataHelper.dropTable()
        SQLSyncOverviewDataHelper.dropTable()
    }
    
    /// Drops and the Creates all tables
    ///
    public func clearTables() {
        dropTables()
        createTables()
    }
    
}