//
//  SQLReportedActionDataHelper.swift
//  Pods
//
//  Created by Akash Desai on 7/18/16.
//
//

import Foundation
import SQLite

typealias SQLReportedAction = (
    index: Int64,
    actionID: String,
    reinforcementDecision: String,
    metaData: [String:AnyObject]?,
    utc: Int64
)

class SQLReportedActionDataHelper : SQLDataHelperProtocol {
    
    typealias T = SQLReportedAction
    
    static let TABLE_NAME = "Reported_Actions"
    
    static let table = Table(TABLE_NAME)
    static let index = Expression<Int64>("index")
    static let actionID = Expression<String>("actionid")
    static let reinforcementDecision = Expression<String>("reinforcementdecision")
    static let metaData = Expression<Blob?>("metadata")
    static let utc = Expression<Int64>("utc")
    
    static let tableQueue = dispatch_queue_create("com.usedopamine.dopaminekit.datastore.ReportedActionsQueue", nil)
    
    static func createTable() {
        dispatch_async(tableQueue) {
            guard let DB = SQLiteDataStore.sharedInstance.DDB else
            {
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
            }
            
            do {
                let _ = try DB.run( table.create(ifNotExists: true) {t in
                    t.column(index, primaryKey: true)
                    t.column(actionID)
                    t.column(reinforcementDecision)
                    t.column(metaData)
                    t.column(utc)
                    })
                DopamineKit.DebugLog("Table \(TABLE_NAME) created!")
            } catch {
                DopamineKit.DebugLog("Error creating table:(\(TABLE_NAME))")
            }
        }
    }
    
    static func dropTable() {
        dispatch_async(tableQueue) {
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
    }
    
    static func insert(item: T) -> Int64? {
        var rowId:Int64?
        dispatch_sync(tableQueue) {
            guard let DB = SQLiteDataStore.sharedInstance.DDB else
            {
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
            }
            
            let insert = table.insert(
                actionID <- item.actionID,
                reinforcementDecision <- item.reinforcementDecision,
                metaData <- (item.metaData==nil ? nil : NSKeyedArchiver.archivedDataWithRootObject(item.metaData!).datatypeValue),
                utc <- item.utc )
            do {
                rowId = try DB.run(insert)
                DopamineKit.DebugLog("Inserted into Table:\(TABLE_NAME) row:\(rowId) actionID:\(item.actionID) reinforcementDecision:\(item.reinforcementDecision)")
            } catch {
                DopamineKit.DebugLog("Insert error for reported action with values actionID:(\(item.actionID)) metaData:(\(item.metaData)) utc:(\(item.utc))")
                return
            }
        }
        return rowId
    }
    
    static func delete (item: T) {
        dispatch_async(tableQueue) {
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
    }
    
    static func find(id: Int64) -> T? {
        var result:T?
        dispatch_sync(tableQueue) {
            guard let DB = SQLiteDataStore.sharedInstance.DDB else
            {
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
            }
            
            let query = table.filter(index == id)
            do {
                let items = try DB.prepare(query)
                for item in  items {
                    result = SQLReportedAction(
                        index: item[index],
                        actionID: item[actionID],
                        reinforcementDecision: item[reinforcementDecision],
                        metaData: item[metaData]==nil ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(NSData.fromDatatypeValue(item[metaData]!)) as? [String:AnyObject],
                        utc: item[utc] )
                }
            } catch {
                DopamineKit.DebugLog("Search error for row in Table:\(TABLE_NAME) with id:\(id)")
            }
        }
        return result
    }
    
    static func findAll() -> [T] {
        var results:[T] = []
        dispatch_sync(tableQueue) {
            guard let DB = SQLiteDataStore.sharedInstance.DDB else
            {
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
            }
            
            do {
                let items = try DB.prepare(table)
                for item in items {
                    results.append(SQLReportedAction(
                        index: item[index] ,
                        actionID: item[actionID],
                        reinforcementDecision: item[reinforcementDecision],
                        metaData: item[metaData]==nil ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(NSData.fromDatatypeValue(item[metaData]!)) as? [String:AnyObject],
                        utc: item[utc] )
                    )
                }
            } catch {
                DopamineKit.DebugLog("Search error for Table:\(TABLE_NAME)")
            }
        }
        return results
    }
    
    static func count() -> Int {
        var result = 0
        dispatch_sync(tableQueue) {
            guard let DB = SQLiteDataStore.sharedInstance.DDB else
            {
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
            }
            
            result = DB.scalar(table.count)
        }
        return result
    }
    
}

