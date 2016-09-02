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
    
    public static let sharedInstance: SQLiteDataStore = SQLiteDataStore()
    
    let DDB: Connection?
    
    /// Creates the SQLite database specific to DopamineKit
    ///
    private override init() {
        var path = "DopamineDB.sqlite"
        if let dirs: [NSString] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as [NSString] {
            let dir = dirs[0]
            path = dir.stringByAppendingPathComponent(path);
            DopamineKit.DebugLog("Sqlite db path:\(path)")
        }
        
        do {
            DDB = try Connection(path)
        } catch _ {
            DopamineKit.DebugLog("Connection to \(path) failed")
            DDB = nil
        }
        
        super.init()
    }
    
    /// Creates all the tables needed for DopamineKit
    ///
    public func createTables(){
        guard let _ = DDB else {
            DopamineKit.DebugLog("No connection to SQLite")
            return
        }
        
        SQLTrackedActionDataHelper.createTable()
        SQLReportedActionDataHelper.createTable()
        SQLCartridgeDataHelper.createTable()
    }
    
    /// Drops all tables used in DopamineKit
    ///
    public func dropTables(){
        guard let _ = DDB else {
            DopamineKit.DebugLog("No connection to SQLite")
            return
        }
        
        SQLTrackedActionDataHelper.dropTable()
        SQLReportedActionDataHelper.dropTable()
        SQLCartridgeDataHelper.dropTable()
    }
    
}