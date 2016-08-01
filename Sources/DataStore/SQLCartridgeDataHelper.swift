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
    
    static let TABLE_NAME_PREFIX = "Reinforcement_Decisions_for_"
    
    static let index = Expression<Int64>("index")
    static let reinforcementDecision = Expression<String>("reinforcementdecision")
    
    private static let tablesQueue:dispatch_queue_t = dispatch_queue_create("com.usedopamine.dopaminekit.datastore.CartridgeQueue", nil)
    
    static func createTable() { }
    
    static func createTable(actionID:String) -> Table? {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return nil
        }
        
        let TABLE_NAME = TABLE_NAME_PREFIX + actionID
        
        do {
            let table = Table(TABLE_NAME)
            let _ = try DB.run( table.create(ifNotExists: true) {t in
                t.column(index, primaryKey: true)
                t.column(reinforcementDecision)
                })
            
            DopamineKit.DebugLog("Table \(TABLE_NAME) created!")
            return table
        } catch {
            DopamineKit.DebugLog("Error creating table:(\(TABLE_NAME))")
            return nil
        }
        return nil
    }

    static func getTable(actionID: String, ifNotExists: Bool=false) -> Table? {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return nil
        }
        let TABLE_NAME = TABLE_NAME_PREFIX + actionID
        do {
            let stmt = try DB.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='\(TABLE_NAME)'")
            for _ in stmt {
                return Table(TABLE_NAME)
            }
        } catch {
            DopamineKit.DebugLog("Error: No table with name (\(TABLE_NAME)) found.")
        }
        if ifNotExists {
            DopamineKit.DebugLog("No table with name (\(TABLE_NAME)) found. Creating it now...")
            return createTable(actionID)
        }
        DopamineKit.DebugLog("Could not find (\(TABLE_NAME)).")
        return nil
    }
    
    static func getTablesCount() -> Int {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return 0
        }
        do {
            let stmt = try DB.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '\(TABLE_NAME_PREFIX)%'")
            var count = 0
            for row in stmt {
                count += 1
            }
            return count
        } catch {
            return 0
        }
    }
    
    static func dropTable() { }
    
    static func dropTable(actionID: String) {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
        { return }
        dispatch_async(tablesQueue) {
            do {
                let _ = try DB.run( table.drop(ifExists: true) )
                DopamineKit.DebugLog("Dropped table:(\(TABLE_NAME_PREFIX + actionID))")
            } catch {
                DopamineKit.DebugLog("Error dropping table:(\(TABLE_NAME_PREFIX + actionID))")
            }
        }
    }
    
    static func dropTables() {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        { return }
        dispatch_async(tablesQueue) {
            do {
                let stmt = try DB.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '\(TABLE_NAME_PREFIX)%'")
                for row in stmt {
                    if let tableName = row[0] as? String {
                        do {
                            let table = Table(tableName)
                            // TOFIX: doesn't delete table. goes to catch clause
                            let _ = try DB.run( table.drop(ifExists: true) )
                            DopamineKit.DebugLog("Dropped table:(\(tableName))")
                        } catch {
                            DopamineKit.DebugLog("Error dropping table:(\(tableName.debugDescription))")
                        }
                    }
                }
            } catch { }
        }
    }
    
    static func insert(item: T) -> Int64? {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(item.actionID, ifNotExists: true) else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return nil
        }
        var rowId:Int64?
        dispatch_sync(tablesQueue) {
            let TABLE_NAME = TABLE_NAME_PREFIX + item.actionID
            let insert = table.insert(
                reinforcementDecision <- item.reinforcementDecision )
            do {
                rowId = try DB.run(insert)
                DopamineKit.DebugLog("Inserted into Table:\(TABLE_NAME) row:\((rowId)) actionID:\((item.actionID)) and reinforcementDecision:(\(item.reinforcementDecision))")
            } catch {
                DopamineKit.DebugLog("Insert error for cartridge table:(\(TABLE_NAME)) values actionID:(\(item.actionID)) and reinforcementDecision:(\(item.reinforcementDecision))")
                return
            }
        }
        return rowId
    }
    
    static func delete (item: T) {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(item.actionID, ifNotExists: false) else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return
        }
        dispatch_async(tablesQueue) {
            let TABLE_NAME = TABLE_NAME_PREFIX + item.actionID
            let id = item.index
            let query = table.filter(index == id)
            do {
                let tmp = try DB.run(query.delete())
                guard tmp == 1 else {
                    throw SQLDataAccessError.Delete_Error
                }
                DopamineKit.DebugLog("Deleted in Table:\(TABLE_NAME) row:\(id) actionID:\(item.actionID) reinforcementDecision:\(item.reinforcementDecision)")
            } catch {
                DopamineKit.DebugLog("❕Could not delete in Table:\(TABLE_NAME) row:\(id)")
            }
        }
    }
    
    static func deleteAll (actionID: String) {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
        { return }
        dispatch_async(tablesQueue) {
            do {
                let result = try DB.run(table.delete())
                guard result == 1 else {
                    throw SQLDataAccessError.Delete_Error
                }
                DopamineKit.DebugLog("Deleted all for Table:\(TABLE_NAME_PREFIX+actionID)")
            } catch {
                DopamineKit.DebugLog("❕Could not delete Table:\(TABLE_NAME_PREFIX+actionID)")
            }
        }
    }
    
    static func find(id: Int64) -> T? { return nil }
    
    static func find(actionID: String, id: Int64) -> T? {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return nil
        }
        var result:T?
        dispatch_sync(tablesQueue) {
            let TABLE_NAME = TABLE_NAME_PREFIX + actionID
            let query = table.filter(index == id)
            do {
                let items = try DB.prepare(query)
                for item in  items {
                    result = SQLCartridge(
                        index: item[index],
                        actionID: actionID,
                        reinforcementDecision: item[reinforcementDecision] )
                }
            } catch {
                DopamineKit.DebugLog("Search error for row in Table:\(TABLE_NAME) with id:\(id)")
            }
        }
        return result
    }
    
    static func pop(actionID: String) -> T? {
        var result:T?
        dispatch_sync(tablesQueue) {
            guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
            {
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
            }
            
            let query = table.order(index.asc).limit(1)
            do {
                let items = try DB.prepare(query)
                for item in  items {
                    let row = SQLCartridge(
                        index: item[index],
                        actionID: actionID,
                        reinforcementDecision: item[reinforcementDecision] )
                    result = row
                    delete(row)
                }
            } catch {
                DopamineKit.DebugLog("Table for:\(actionID) is empty")
            }
        }
        return result
    }
    
    static func findAll() -> [T] { return [] }
    
    static func findAll(actionID:String) -> [T] {
        var results:[T] = []
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return results
        }
        dispatch_sync(tablesQueue) {
            var results:[T] = []
            do {
                let items = try DB.prepare(table)
                for item in items {
                    results.append(SQLCartridge(
                        index: item[index],
                        actionID: actionID,
                        reinforcementDecision: item[reinforcementDecision] )
                    )
                }
            } catch {
                DopamineKit.DebugLog("Search error for Table:\(TABLE_NAME_PREFIX + actionID)")
            }
        }
        return results
    }
    
    static func count(actionID: String) -> Int {
        var result = 0
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
        { return result }
        dispatch_sync(tablesQueue) {
            result = DB.scalar(table.count)
        }
        return result
    }
    
}

