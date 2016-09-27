//
//  SQLSyncOverviewDataHelper.swift
//  Pods
//
//  Created by Akash Desai on 9/12/16.
//
//

import Foundation
import SQLite

typealias SQLSyncOverview = (
    index: Int64,
    utc: Int64,
    timezoneOffset: Int64,
    totalSyncTime: Int64,
    cause: String,
    track: [String: AnyObject],
    report: [String: AnyObject],
    cartridges: [[String: AnyObject]]?
)

class SQLSyncOverviewDataHelper : SQLDataHelperProtocol {
    
    typealias T = SQLSyncOverview
    
    static let TABLE_NAME = "Sync_Overviews"
    static let table = Table(TABLE_NAME)
    
    static let index = Expression<Int64>("index")
    static let utc = Expression<Int64>("utc")
    static let timezoneOffset = Expression<Int64>("timezoneOffset")
    static let totalSyncTime = Expression<Int64>("totalSyncTime")
    static let cause = Expression<String>("cause")
    static let track = Expression<Blob>("track")
    static let report = Expression<Blob>("report")
    static let cartridges = Expression<Blob?>("cartridges")
        
    static let tableQueue = dispatch_queue_create("com.usedopamine.dopaminekit.datastore.SyncOverviewQueue", nil)
    
    /// Creates a SQLite table for sync overviews
    ///
    /// Called in SQLiteDataStore.sharedInstance.createTables()
    ///
    static func createTable() {
        dispatch_async(tableQueue) {
            guard let DB = SQLiteDataStore.sharedInstance.DDB else
            { utc.template
                DopamineKit.DebugLog("SQLite database never initialized.")
                return
            }
            do {
                let _ = try DB.run( table.create(ifNotExists: true) {t in
                    t.column(index, primaryKey: true)
                    t.column(utc)
                    t.column(timezoneOffset)
                    t.column(totalSyncTime)
                    t.column(cause)
                    t.column(track)
                    t.column(report)
                    t.column(cartridges)
                    }
                )
                DopamineKit.DebugLog("Table \(TABLE_NAME) created!")
            } catch {
                DopamineKit.DebugLog("Error creating table:(\(TABLE_NAME))")
            }
        }
    }
    
    /// Drops the table for sync overviews
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
    
    /// Inserts a sync overview into the SQLite table
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
                rowId = nil
                return
            }
            
            let insert = table.insert(
                utc <- item.utc,
                timezoneOffset <- item.timezoneOffset,
                totalSyncTime <- item.totalSyncTime,
                cause <- item.cause,
                track <- NSKeyedArchiver.archivedDataWithRootObject(item.track).datatypeValue,
                report <- NSKeyedArchiver.archivedDataWithRootObject(item.report).datatypeValue,
                cartridges <- (item.cartridges==nil ? nil : NSKeyedArchiver.archivedDataWithRootObject(item.cartridges!).datatypeValue)
            )
            do {
                rowId = try DB.run(insert)
                DopamineKit.DebugLog("Inserted into Table:\(TABLE_NAME) row:\(rowId) for sync caused by:\(item.cause)")
                return
            } catch {
                DopamineKit.DebugLog("Insert error for inserting sync overview caused by:\(item.cause)")
                rowId = nil
                return
            }
        }
        return rowId
    }
    
    /// Deletes a sync overview from the SQLite table
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
    
    /// Finds a sync overview by id from the SQLite table
    ///
    /// - parameters:
    ///     - id: The index for the sync overview row.
    ///
    static func find(id: Int64) -> T? {
        var result:SQLSyncOverview?
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
                    result = SQLSyncOverview(
                        index: item[index],
                        utc: item[utc],
                        timezoneOffset: item[timezoneOffset],
                        totalSyncTime: item[totalSyncTime],
                        cause:item[cause],
                        track: NSKeyedUnarchiver.unarchiveObjectWithData(NSData.fromDatatypeValue(item[track])) as! [String: AnyObject],
                        report: NSKeyedUnarchiver.unarchiveObjectWithData(NSData.fromDatatypeValue(item[report])) as! [String: AnyObject],
                        cartridges: item[cartridges]==nil ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(NSData.fromDatatypeValue(item[cartridges]!)) as? [[String: AnyObject]]
                    )
                    break
                }
            } catch {
                DopamineKit.DebugLog("Search error for row in Table:\(TABLE_NAME) with id:\(id)")
            }
        }
        return result
    }
    
    /// Finds all sync overviews from the SQLite table
    ///
    /// - returns: All rows from the sync overview table.
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
                    results.append( SQLSyncOverview(
                        index: item[index],
                        utc: item[utc],
                        timezoneOffset: item[timezoneOffset],
                        totalSyncTime: item[totalSyncTime],
                        cause:item[cause],
                        track: NSKeyedUnarchiver.unarchiveObjectWithData(NSData.fromDatatypeValue(item[track])) as! [String: AnyObject],
                        report: NSKeyedUnarchiver.unarchiveObjectWithData(NSData.fromDatatypeValue(item[report])) as! [String: AnyObject],
                        cartridges: item[cartridges]==nil ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(NSData.fromDatatypeValue(item[cartridges]!)) as? [[String: AnyObject]]
                        )
                    )
                }
            } catch {
                DopamineKit.DebugLog("Search error for Table:\(TABLE_NAME)")
            }
        }
        return results
    }
    
    /// How many rows total are in the sync overview table
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
    static func decodeJSONForItem(item: T) -> [String:AnyObject] {
        var jsonObject: [String:AnyObject] = [:]
        
        jsonObject["utc"] = NSNumber(longLong: item.utc)
        jsonObject["timezoneOffset"] = NSNumber(longLong: item.timezoneOffset)
        jsonObject["totalSyncTime"] = NSNumber(longLong: item.totalSyncTime)
        jsonObject["cause"] = item.cause
        jsonObject["track"] = item.track
        jsonObject["report"] = item.report
        jsonObject["cartridges"] = item.cartridges
        
        return jsonObject
    }
    
}

