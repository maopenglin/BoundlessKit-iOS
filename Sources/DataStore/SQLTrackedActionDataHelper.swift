//
//  SQLTrackedActionDataHelper.swift
//  Pods
//
//  Created by Akash Desai on 7/18/16.
//
//

import Foundation
import SQLite


typealias SQLTrackedAction = (
    index: Int64,
    actionID: String,
    metaData: [String:AnyObject]?,
    utc: Int64
)


public class SQLTrackedActionDataHelper : SQLDataHelperProtocol {
    
    static let TABLE_NAME = "Tracked_Actions"
    
    static let table = Table(TABLE_NAME)
    static let index = Expression<Int64>("index")
    static let actionID = Expression<String>("actionid")
    static let metaData = Expression<Blob?>("metadata")
    static let utc = Expression<Int64>("utc")
    
    typealias T = SQLTrackedAction
    
    static func createTable() {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
        }
        do {
            let _ = try DB.run( table.create(ifNotExists: true) {t in
                t.column(index, primaryKey: true)
                t.column(actionID)
                t.column(metaData)
                t.column(utc)
                })
            DopamineKit.DebugLog("Table \(TABLE_NAME) created!")
        } catch {
            DopamineKit.DebugLog("Error creating table:(\(TABLE_NAME))")
        }
        
    }
    
    public static func dropTable() {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return
        }
        do {
            let _ = try DB.run( table.drop(ifExists: true) )
            DopamineKit.DebugLog("Dropped table:(\(TABLE_NAME))")
        } catch {
            DopamineKit.DebugLog("Error dropping table:(\(TABLE_NAME))")
        }
    }
    
    static func insert(item: T) -> Int64? {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return nil
        }
        
        let insert = table.insert(
            actionID <- item.actionID,
            metaData <- (item.metaData==nil ? nil : NSKeyedArchiver.archivedDataWithRootObject(item.metaData!).datatypeValue),
            utc <- item.utc )
        do {
            let rowId = try DB.run(insert)
            DopamineKit.DebugLog("Inserted into Table:\(TABLE_NAME) row:\(rowId) actionID:\(item.actionID)")
            return rowId
        } catch {
            DopamineKit.DebugLog("Insert error for tracked action values: actionID:(\(item.actionID)) metaData:(\(item.metaData)) utc:(\(item.utc))")
            return nil
        }
    }
    
    static func delete (item: T) -> Void {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return
        }
        
        let id = item.index
        let query = table.filter(index == id)
        do {
            let tmp = try DB.run(query.delete())
            guard tmp == 1 else {
                throw SQLDataAccessError.Delete_Error
            }
            DopamineKit.DebugLog("Delete for Table:\(TABLE_NAME) row:\(id) successful")
        } catch {
            DopamineKit.DebugLog("Delete for Table:\(TABLE_NAME) row:\(id) failed")
        }
        
    }
    
    static func find(id: Int64) -> T? {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return nil
        }
        
        let query = table.filter(index == id)
        do {
            let items = try DB.prepare(query)
            for item:Row in  items {
                return SQLTrackedAction(
                    index: item[index] ,
                    actionID: item[actionID],
                    metaData: item[metaData]==nil ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(NSData.fromDatatypeValue(item[metaData]!)) as? [String:AnyObject],
                    utc: item[utc] )
            }
        } catch {
            DopamineKit.DebugLog("Search error for row in Table:\(TABLE_NAME) with id:\(id)")
        }
        
        return nil
    }
    
    static func findAll() -> [T] {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return []
        }
        
        var results = [T]()
        do {
            let items = try DB.prepare(table)
            for item in items {
                results.append( SQLTrackedAction(
                    index: item[index],
                    actionID: item[actionID],
                    metaData: item[metaData]==nil ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(NSData.fromDatatypeValue(item[metaData]!)) as? [String:AnyObject],
                    utc: item[utc] )
                )
            }
        } catch {
            DopamineKit.DebugLog("Search error for Table:\(TABLE_NAME)")
        }
        
        return results
    }
    
    static func count() -> Int {
        
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return 0
        }
        
        return DB.scalar(table.count)
    }
    
}

