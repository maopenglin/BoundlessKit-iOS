//
//  SQLCartridgeDataHelper.swift
//  Pods
//
//  Created by Akash Desai on 7/19/16.
//
//

import Foundation
import SQLite

typealias SQLCartridge = (
    index: Int64,
    actionID: String,
    reinforcementDecision: String
)

class SQLCartridgeDataHelper : SQLDataHelperProtocol {
    
    typealias T = SQLCartridge
    
    static let TABLE_NAME = "Reinforcement_Decisions"
    
    static let table = Table(TABLE_NAME)
    static let index = Expression<Int64>("index")
    static let actionID = Expression<String>("actionid")
    static let reinforcementDecision = Expression<String>("reinforcementdecision")
    
    private static let tableQueue:dispatch_queue_t = dispatch_queue_create("com.usedopamine.dopaminekit.datastore.ReinforcementDecisionsQueue", nil)
    
    /// Creates a SQLite table for reinforcement decisions
    ///
    /// Called in SQLiteDataStore.sharedInstance.createTables()
    ///
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
                    })
                
                DopamineKit.DebugLog("Table \(TABLE_NAME) created!")
            } catch {
                DopamineKit.DebugLog("Error creating table:(\(TABLE_NAME))")
            }
        }
    }
    
    /// Drops the table for reinforcement decisions
    ///
    /// Called in SQLiteDataStore.sharedInstance.dropTables()
    ///
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
    
    /// Inserts a reinforcement decisions into the SQLite table
    ///
    /// - parameters:
    ///     - item: A sql row with meaningful values for all columns except index.
    ///
    /// - returns:
    ///     The row the item was added into.
    ///
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
                reinforcementDecision <- item.reinforcementDecision
            )
            do {
                rowId = try DB.run(insert)
                DopamineKit.DebugLog("Inserted into Table:\(TABLE_NAME) row:\(rowId) actionID:\(item.actionID) reinforcementDecision:\(item.reinforcementDecision)")
            } catch {
                DopamineKit.DebugLog("Insert error for reinforcement decision with values actionID:(\(item.actionID)) reinforcementDecision:(\(item.reinforcementDecision))")
                return
            }
        }
        return rowId
    }
    
    /// Deletes a reinforcement decision from the SQLite table
    ///
    /// - parameters:
    ///     - item: A sql row with the index to delete.
    ///
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
                let numDeleted = try DB.run(query.delete())
                
                DopamineKit.DebugLog("Delete \(numDeleted) items from Table:\(TABLE_NAME) row:\(id) successful")
            } catch {
                DopamineKit.DebugLog("Delete for Table:\(TABLE_NAME) row:\(id) failed")
            }
        }
    }
    
    /// Deletes all reinforcement decisions from the SQLite table for a specific actionID
    ///
    /// - parameters:
    ///     - action: The actionID to filter for and delete from the table.
    ///
    static func deleteAllFor (action: String) {
        dispatch_async(tableQueue) {
            guard let DB = SQLiteDataStore.sharedInstance.DDB else
            {
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
            }
            
            let query = table.filter(actionID == action)
            do {
                let numDeleted = try DB.run(query.delete())
                
                DopamineKit.DebugLog("Deleted \(numDeleted) items from Table:\(TABLE_NAME) with actionID:\(action) successful")
            } catch {
                DopamineKit.DebugLog("Delete for Table:\(TABLE_NAME) actionID:\(action) failed")
            }
        }
    }
    
    /// Finds all reinforcement decisions from the SQLite table
    ///
    /// - returns: All rows from the reinforcement decisions table.
    ///
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
                    results.append(SQLCartridge(
                        index: item[index] ,
                        actionID: item[actionID],
                        reinforcementDecision: item[reinforcementDecision] )
                    )
                }
            } catch {
                DopamineKit.DebugLog("Search error for Table:\(TABLE_NAME)")
            }
        }
        return results
    }
    
    /// Used to unload a reinforcement decision from a cartridge
    ///
    /// - parameters:
    ///     - action: The actionID to find the first reinforcement decision for.
    ///
    /// - returns: The first row for the given actionID
    ///
    static func findFirstFor(action: String) -> T? {
        var result:T?
        dispatch_sync(tableQueue) {
            guard let DB = SQLiteDataStore.sharedInstance.DDB else
            {
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
            }
            
            let query = table.filter(actionID == action).order(index.asc).limit(1)
            do {
                let items = try DB.prepare(query)
                for item in  items {
                    let row = SQLCartridge(
                        index: item[index],
                        actionID: item[actionID],
                        reinforcementDecision: item[reinforcementDecision] )
                    result = row
                }
            } catch {
                DopamineKit.DebugLog("Search error for row in Table:\(TABLE_NAME) with actionID:\(action)")
            }
        }
        return result
    }
    
    /// How many rows total are in the reinforcement decisions table
    ///
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
    
    /// How many rows are in the reinforcement decisions table for a specific actionID
    ///
    /// - parameters:
    ///     - action: The actionID to filter the table
    ///
    static func countFor(action: String) -> Int {
        var result = 0
        dispatch_sync(tableQueue) {
            guard let DB = SQLiteDataStore.sharedInstance.DDB else
            {
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
            }
            
            result = DB.scalar(table.filter(actionID == action).count)
        }
        return result
    }
    
}

