//
//  SQLDopeExceptionDataHelper.swift
//  Pods
//
//  Created by Akash Desai on 9/26/16.
//
//

import Foundation
import SQLite

typealias SQLDopeException = (
    index: Int64,
    utc: Int64,
    timezoneOffset: Int64,
    exceptionClassName: String,
    message: String,
    stackTrace: String
)

class SQLDopeExceptionDataHelper : SQLDataHelperProtocol {
    
    typealias T = SQLDopeException
    
    
    static let TABLE_NAME = "Dope_Exceptions"
    static let table = Table(TABLE_NAME)
    
    static let index = Expression<Int64>("index")
    static let utc = Expression<Int64>("utc")
    static let timezoneOffset = Expression<Int64>("timezoneOffset")
    static let exceptionClassName = Expression<String>("exceptionClassName")
    static let message = Expression<String>("message")
    static let stackTrace = Expression<String>("stackTrace")
    
    static let tableQueue = dispatch_queue_create("com.usedopamine.dopaminekit.datastore.DopeExceptionsQueue", nil)
    
    /// Creates a SQLite table for dopamine exceptions
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
                    t.column(utc)
                    t.column(timezoneOffset)
                    t.column(exceptionClassName)
                    t.column(message)
                    t.column(stackTrace)
                    }
                )
                DopamineKit.DebugLog("Table \(TABLE_NAME) created!")
            } catch {
                DopamineKit.DebugLog("Error creating table:(\(TABLE_NAME))")
            }
        }
    }
    
    /// Drops the table for dopamine exceptions
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
    
    /// Inserts a dopamine exceptions into the SQLite table
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
                utc <- item.utc,
                timezoneOffset <- item.timezoneOffset,
                exceptionClassName <- item.exceptionClassName,
                message <- item.message,
                stackTrace <- item.stackTrace
            )
            do {
                rowId = try DB.run(insert)
                DopamineKit.DebugLog("Inserted into Table:\(TABLE_NAME) row:\(rowId) exception with className:\(item.exceptionClassName) message:\(item.message) stackTrace:\(item.stackTrace)")
            } catch {
                DopamineKit.DebugLog("Insert error for exception with className:\(item.exceptionClassName) message:\(item.message) stackTrace:\(item.stackTrace)")
                return
            }
        }
        return rowId
    }
    
    /// Deletes a dopamine exception from the SQLite table
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
                
                DopamineKit.DebugLog("Deleted \(numDeleted) items from Table:\(TABLE_NAME) row:\(id) successful")
            } catch {
                DopamineKit.DebugLog("Delete for Table:\(TABLE_NAME) row:\(id) failed")
            }
        }
    }
    
    /// Finds a dopamine exception by id from the SQLite table
    ///
    /// - parameters:
    ///     - id: The index to find the dopamine exception action.
    ///
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
                    result = SQLDopeException(
                        index: item[index],
                        utc: item[utc],
                        timezoneOffset: item[timezoneOffset],
                        exceptionClassName: item[exceptionClassName],
                        message: item[message],
                        stackTrace: item[stackTrace]
                    )
                    break
                }
            } catch {
                DopamineKit.DebugLog("Search error for row in Table:\(TABLE_NAME) with id:\(id)")
            }
        }
        return result
    }
    
    /// Finds all dopamine exceptions from the SQLite table
    ///
    /// - returns: All rows from the dopamine exception table.
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
                    results.append( SQLDopeException(
                        index: item[index],
                        utc: item[utc],
                        timezoneOffset: item[timezoneOffset],
                        exceptionClassName: item[exceptionClassName],
                        message: item[message],
                        stackTrace: item[stackTrace]
                        )
                    )
                }
            } catch {
                DopamineKit.DebugLog("Search error for Table:\(TABLE_NAME)")
            }
        }
        return results
    }
    
    /// How many rows total are in the dopamine exceptions table
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
    
    /// Converts the item into a JSON object
    ///
    static func decodeJSONForItem(item: T) -> [String: AnyObject] {
        var jsonObject: [String:AnyObject] = [:]
        
        jsonObject["utc"] = NSNumber(longLong: item.utc)
        jsonObject["timezoneOffset"] = NSNumber(longLong: item.timezoneOffset)
        jsonObject["exceptionClassName"] = item.exceptionClassName
        jsonObject["message"] = item.message
        jsonObject["stackTrace"] = item.stackTrace
        
        return jsonObject
    }
    
}
