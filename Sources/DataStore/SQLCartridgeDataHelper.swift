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
    
    static let TABLE_NAME_PREFIX = "Reinforcement_Decisions_for_"
    
    static let index = Expression<Int64>("index")
    static let reinforcementDecision = Expression<String>("reinforcementdecision")
    
    typealias T = SQLCartridge
    
    static func createTable() { }
    
    static func createTable(actionID:String) -> Table? {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return nil
        }
        
        let TABLE_NAME = TABLE_NAME_PREFIX + actionID
        let table = Table(TABLE_NAME)
        
        do {
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
    
    static func dropTable() { }
    
    static func dropTable(actionID: String) {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
        { return }
        do {
            let _ = try DB.run( table.drop(ifExists: true) )
            DopamineKit.DebugLog("Dropped table:(\(TABLE_NAME_PREFIX + actionID))")
        } catch {
            DopamineKit.DebugLog("Error dropping table:(\(TABLE_NAME_PREFIX + actionID))")
        }
    }
    
    static func dropTables() {
        guard let DB = SQLiteDataStore.sharedInstance.DDB else
        { return }
        
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
    
    static func insert(item: T) -> Int64? {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(item.actionID, ifNotExists: true) else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return nil
        }
        
        let TABLE_NAME = TABLE_NAME_PREFIX + item.actionID
        let insert = table.insert(
            reinforcementDecision <- item.reinforcementDecision )
        do {
            let rowId = try DB.run(insert)
            DopamineKit.DebugLog("Inserted into Table:\(TABLE_NAME) row:\((rowId)) actionID:\((item.actionID)) and reinforcementDecision:(\(item.reinforcementDecision))")
            return rowId
        } catch {
            DopamineKit.DebugLog("Insert error for cartridge table:(\(TABLE_NAME)) values actionID:(\(item.actionID)) and reinforcementDecision:(\(item.reinforcementDecision))")
            return nil
        }
    }
    
    static func delete (item: T) {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(item.actionID, ifNotExists: false) else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return
        }
        
        let TABLE_NAME = TABLE_NAME_PREFIX + item.actionID
        let id = item.index
        let query = table.filter(index == id)
        do {
            let tmp = try DB.run(query.delete())
            guard tmp == 1 else {
                throw SQLDataAccessError.Delete_Error
            }
            DopamineKit.DebugLog("Delete for Table:\(TABLE_NAME) row:\(id) actionID:\(item.actionID) reinforcementDecision:\(item.reinforcementDecision) successful")
        } catch {
            DopamineKit.DebugLog("Delete for Table:\(TABLE_NAME) row:\(id) failed")
        }
        
    }
    
    static func find(id: Int64) -> T? { return nil }
    
    static func find(actionID: String, id: Int64) -> T? {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return nil
        }
        
        let TABLE_NAME = TABLE_NAME_PREFIX + actionID
        let query = table.filter(index == id)
        do {
            let items = try DB.prepare(query)
            for item in  items {
                return SQLCartridge(
                    index: item[index],
                    actionID: actionID,
                    reinforcementDecision: item[reinforcementDecision] )
            }
        } catch {
            DopamineKit.DebugLog("Search error for row in Table:\(TABLE_NAME) with id:\(id)")
        }
        
        return nil
    }
    
    static func findFirst(actionID: String) -> T? {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return nil
        }
        
        let query = table.order(index.asc).limit(1)
        do {
            let items = try DB.prepare(query)
            for item in  items {
                return SQLCartridge(
                    index: item[index],
                    actionID: actionID,
                    reinforcementDecision: item[reinforcementDecision] )
            }
        } catch {
            DopamineKit.DebugLog("Table for:\(actionID) is empty")
        }
        
        return nil
    }
    
    static func findAll() -> [T] { return [] }
    
    static func findAll(actionID:String) -> [T] {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
        {
            DopamineKit.DebugLog("SQLite database never initialized.")
            return []
        }
        
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
        
        return results
    }
    
    static func count(actionID: String) -> Int {
        guard let DB = SQLiteDataStore.sharedInstance.DDB, table = getTable(actionID, ifNotExists: false) else
        {
            return 0
        }
        return DB.scalar(table.count)
    }
    
}

