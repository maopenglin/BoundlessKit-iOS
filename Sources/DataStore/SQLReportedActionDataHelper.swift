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
    metaData: Blob?,
    utc: Int64,
    timezoneOffset: Int64
)


class SQLReportedActionDataHelper : SQLDataHelperProtocol {
    
    static let TABLE_NAME = "Reinforced_Actions"
    
    static let table = Table(TABLE_NAME)
    static let index = Expression<Int64>("index")
    static let actionID = Expression<String>("actionid")
    static let reinforcementDecision = Expression<String>("reinforcementdecision")
    static let metaData = Expression<Blob?>("metadata")
    static let utc = Expression<Int64>("utc")
    static let timezoneOffset = Expression<Int64>("timezoneoffset")
    
    typealias T = SQLReportedAction
    
    static func createTable() {
        let DB = SQLiteDataStore.instance.DDB!
        
        do {
            let _ = try DB.run( table.create(ifNotExists: true) {t in
                t.column(index, primaryKey: true)
                t.column(actionID)
                t.column(reinforcementDecision)
                t.column(metaData)
                t.column(utc)
                t.column(timezoneOffset)
                })
            DopamineKit.DebugLog("Table \(TABLE_NAME) created!")
        } catch {
            DopamineKit.DebugLog("Error creating table:(\(TABLE_NAME))")
        }
        
    }
    
    static func dropTable() {
        let DB = SQLiteDataStore.instance.DDB!
        do {
            let _ = try DB.run( table.drop(ifExists: true) )
        } catch {
            DopamineKit.DebugLog("Error dropping table:(\(TABLE_NAME))")
        }
    }
    
    static func insert(item: T) -> Int64? {
        let DB = SQLiteDataStore.instance.DDB!
        
        let insert = table.insert(actionID <- item.actionID, reinforcementDecision <- item.reinforcementDecision, metaData <- item.metaData?.datatypeValue, utc <- item.utc, timezoneOffset <- item.timezoneOffset)
        do {
            let rowId = try DB.run(insert)
            DopamineKit.DebugLog("Inserted into Table:\(TABLE_NAME) row:\(rowId) actionID:\(item.actionID)")
            return rowId
        } catch {
            DopamineKit.DebugLog("Insert error for reported action with values actionID:(\(item.actionID)) utc:(\(item.utc)) timezoneOffset(\(item.timezoneOffset))")
            return nil
        }
    }
    
    static func delete (item: T) -> Void {
        let DB = SQLiteDataStore.instance.DDB!
        
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
        let DB = SQLiteDataStore.instance.DDB!
        
        let query = table.filter(index == id)
        do {
            let items = try DB.prepare(query)
            for item in  items {
                return SQLReportedAction(index: item[index] , actionID: item[actionID], reinforcementDecision: item[reinforcementDecision], metaData: item[metaData], utc: item[utc], timezoneOffset: item[timezoneOffset])
            }
        } catch {
            DopamineKit.DebugLog("Search error for row in Table:\(TABLE_NAME) with id:\(id)")
        }
        
        return nil
    }
    
    static func findAll() -> [T] {
        let DB = SQLiteDataStore.instance.DDB!
        
        var results = [T]()
        do {
            let items = try DB.prepare(table)
            for item in items {
                results.append(SQLReportedAction(index: item[index] , actionID: item[actionID], reinforcementDecision: item[reinforcementDecision], metaData: item[metaData], utc: item[utc], timezoneOffset: item[timezoneOffset]))
            }
        } catch {
            DopamineKit.DebugLog("Search error for Table:\(TABLE_NAME)")
        }
        
        return results
    }
    
}

