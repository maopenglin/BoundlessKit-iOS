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
    public static let instance: SQLiteDataStore = SQLiteDataStore()
    
    let DDB: Connection?
    
    private override init() {
        var path = "DopamineDB.sqlite"
        
        if let dirs: [NSString] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as [NSString] {
            let dir = dirs[0]
            path = dir.stringByAppendingPathComponent(path);
        }
        
        do {
            DDB = try Connection(path)
        } catch _ {
            DDB = nil
        }
    }
    
    
    
    func createTables() throws{
        do {
            try SQLTrackedActionDataHelper.createTable()
//            try ReinforcedActionDataHelper.createTable()
        } catch {
            throw SQLDataAccessError.Datastore_Connection_Error
        }
    }
    
    
    
    
    
    
    
    
    static func writeTrack(event: DopeAction){
        _ = self.instance
    }
    
    static func writeReinforcement(event: DopeAction){
        _ = self.instance
    }
    
}