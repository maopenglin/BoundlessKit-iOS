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
    static var tables:[String:Table] = [:]
    
    static let index = Expression<Int64>("index")
    static let reinforcementDecision = Expression<String>("reinforcementdecision")
    
    typealias T = SQLCartridge
    
    static func createTable() { }
    
    static func createTable(actionID:String){
        let DB = SQLiteDataStore.instance.DDB!
        let TABLE_NAME = TABLE_NAME_PREFIX + actionID
        
        do {
            let table = Table(TABLE_NAME)
            let _ = try DB.run( table.create(ifNotExists: true) {t in
                t.column(index, primaryKey: true)
                t.column(reinforcementDecision)
                })
            DopamineKit.DebugLog("Table \(TABLE_NAME) created!")
            tables[actionID] = table
        } catch {
            DopamineKit.DebugLog("Error creating table:(\(TABLE_NAME))")
        }
    }
    
    
    static func dropTable() {}
    
    static func dropTable(actionID: String) {
        let DB = SQLiteDataStore.instance.DDB!
        let TABLE_NAME = TABLE_NAME_PREFIX + actionID
        let table:Table = tables[TABLE_NAME]==nil ? Table(TABLE_NAME) : tables[TABLE_NAME]!
        
        do {
            let _ = try DB.run( table.drop(ifExists: true) )
            DopamineKit.DebugLog("Dropped table:(\(TABLE_NAME))")
        } catch {
            DopamineKit.DebugLog("Error dropping table:(\(TABLE_NAME))")
        }
    }
    
    static func insert(item: T) -> Int64? {
        let DB = SQLiteDataStore.instance.DDB!
        let TABLE_NAME = TABLE_NAME_PREFIX + item.actionID
        let table = tables[item.actionID]!
        
        let insert = table.insert(
            reinforcementDecision <- item.reinforcementDecision )
        do {
            let rowId = try DB.run(insert)
            DopamineKit.DebugLog("Inserted into Table:\(TABLE_NAME) row:\(rowId) actionID:\(item.actionID)")
            return rowId
        } catch {
            DopamineKit.DebugLog("Insert error for cartridge table:(\(TABLE_NAME)) values actionID:(\(item.actionID)) and reinforcementDecision:(\(item.reinforcementDecision))")
            return nil
        }
    }
    
    static func delete (item: T) -> Void {
        let DB = SQLiteDataStore.instance.DDB!
        let TABLE_NAME = TABLE_NAME_PREFIX + item.actionID
        let table:Table = tables[TABLE_NAME]==nil ? Table(TABLE_NAME) : tables[TABLE_NAME]!
        
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
    
    static func find(id: Int64) -> T? { return nil }
    
    static func find(actionID: String, id: Int64) -> T? {
        let DB = SQLiteDataStore.instance.DDB!
        let TABLE_NAME = TABLE_NAME_PREFIX + actionID
        let table:Table = tables[TABLE_NAME]==nil ? Table(TABLE_NAME) : tables[TABLE_NAME]!
        
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
    
    static func findLast(actionID: String) -> T? {
        let DB = SQLiteDataStore.instance.DDB!
        let TABLE_NAME = TABLE_NAME_PREFIX + actionID
        let table:Table = tables[TABLE_NAME]==nil ? Table(TABLE_NAME) : tables[TABLE_NAME]!
        
        let query = table.order(index.desc).limit(1)
        do {
            let items = try DB.prepare(query)
            for item in  items {
                return SQLCartridge(
                    index: item[index],
                    actionID: actionID,
                    reinforcementDecision: item[reinforcementDecision] )
            }
        } catch {
            DopamineKit.DebugLog("Table:\(TABLE_NAME) is empty")
        }
        
        return nil
    }
    
    static func findAll() -> [T] { return [] }
    
    static func findAll(actionID:String) -> [T] {
        let DB = SQLiteDataStore.instance.DDB!
        let TABLE_NAME = TABLE_NAME_PREFIX + actionID
        let table:Table = tables[TABLE_NAME]==nil ? Table(TABLE_NAME) : tables[TABLE_NAME]!
        
        var results = [T]()
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
            DopamineKit.DebugLog("Search error for Table:\(TABLE_NAME)")
        }
        
        return results
    }
    
}

