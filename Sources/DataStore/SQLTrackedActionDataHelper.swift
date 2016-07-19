//
//  TrackedActionDataHelper.swift
//  Pods
//
//  Created by Akash Desai on 7/18/16.
//
//

import Foundation
import SQLite


typealias SQLTrackedAction = (
    index: Int64?,
    actionID: String?,
//    metaData: NSData?,
    utc: Int64?,
    timezoneOffset: Int64?
)


class SQLTrackedActionDataHelper : SQLDataHelperProtocol {
    
    static let TABLE_NAME = "Tracked_Actions"
    
    static let table = Table(TABLE_NAME)
    static let index = Expression<Int64>("index")
    static let actionID = Expression<String>("actionid")
//    static let metaData = Expression<SQLite.Blob>("metadata")
    static let utc = Expression<Int64>("utc")
    static let timezoneOffset = Expression<Int64>("timezoneoffset")
    
    typealias T = SQLTrackedAction
    
    static func createTable() throws {
        guard let DB = SQLiteDataStore.instance.DDB else {
            throw SQLDataAccessError.Datastore_Connection_Error
        }
        do {
            let _ = try DB.run( table.create(ifNotExists: true) {t in
                t.column(index, primaryKey: true)
                t.column(actionID)
//                t.column(metaData)
                t.column(utc)
                t.column(timezoneOffset)
                })
            
        } catch _ {
            // Error caught if table already exists
            DopamineKit.DebugLog("Table:(\(TABLE_NAME)) already created")
            
        }
        
    }
    
    static func dropTable() throws {
        guard let DB = SQLiteDataStore.instance.DDB else {
            throw SQLDataAccessError.Datastore_Connection_Error
        }
        do {
            let _ = try DB.run( table.drop(ifExists: true) )
            
        } catch _ {
            // Error caught if table already exists
            DopamineKit.DebugLog("Table:(\(TABLE_NAME)) already created")
            
        }
    }
    
    static func insert(item: T) throws -> Int64 {
        guard let DB = SQLiteDataStore.instance.DDB else {
            throw SQLDataAccessError.Datastore_Connection_Error
        }
        if (item.actionID != nil && item.utc != nil && item.timezoneOffset != nil) {
            let insert = table.insert(actionID <- item.actionID!, utc <- item.utc!, timezoneOffset <- item.timezoneOffset!)
            do {
                let rowId = try DB.run(insert)
                guard rowId > 0 else {
                    throw SQLDataAccessError.Insert_Error
                }
                return rowId
            } catch _ {
                DopamineKit.DebugLog("Insert error for tracked action values: actionID:(\(item.actionID)) utc:(\(item.utc)) timezoneOffset(\(item.timezoneOffset))")
                throw SQLDataAccessError.Insert_Error
            }
        } else {
            DopamineKit.DebugLog("Invalid tracked action values: actionID:(\(item.actionID)) utc:(\(item.utc)) timezoneOffset(\(item.timezoneOffset))")
        }
        throw SQLDataAccessError.Nil_In_Data
        
    }
    
    static func delete (item: T) throws -> Void {
        guard let DB = SQLiteDataStore.instance.DDB else {
            throw SQLDataAccessError.Datastore_Connection_Error
        }
        if let id = item.index {
            let query = table.filter(index == id)
            do {
                let tmp = try DB.run(query.delete())
                guard tmp == 1 else {
                    throw SQLDataAccessError.Delete_Error
                }
            } catch _ {
                throw SQLDataAccessError.Delete_Error
            }
        }
    }
    
    static func find(id: Int64) throws -> T? {
        guard let DB = SQLiteDataStore.instance.DDB else {
            throw SQLDataAccessError.Datastore_Connection_Error
        }
        let query = table.filter(index == id)
        
        do {
            let items = try DB.prepare(query)
            for item in  items {
////                guard var itemMetaData:[String:AnyObject] = NSKeyedUnarchiver(forReadingWithData: NSData.fromDatatypeValue(item[metaData])) as NSDictionary! else {
//                    return nil
//                }
                return SQLTrackedAction(index: item[index] , actionID: item[actionID], utc: item[utc], timezoneOffset: item[timezoneOffset])
            }
        } catch _ {
            throw SQLDataAccessError.Search_Error
        }
        
        return nil
    }
    
    static func findAll() throws -> [T]? {
        guard let DB = SQLiteDataStore.instance.DDB else {
            throw SQLDataAccessError.Datastore_Connection_Error
        }
        var results = [T]()
        do {
            let items = try DB.prepare(table)
            for item in items {
//                guard var itemMetaData:[String:AnyObject] = NSKeyedUnarchiver
                results.append(SQLTrackedAction(index: item[index] , actionID: item[actionID], utc: item[utc], timezoneOffset: item[timezoneOffset]))
            }
        } catch {
            throw SQLDataAccessError.Search_Error
        }
        
        return results
    }
    
    static func lastIndex() throws -> Int64 {
        guard let DB = SQLiteDataStore.instance.DDB else {
            throw SQLDataAccessError.Datastore_Connection_Error
        }
        let query = table.order(index.desc).limit(1)
        do {
            let items = try DB.prepare(query)
            for item in  items {
                return item[index]
            }
        } catch _ {
            throw SQLDataAccessError.Search_Error
        }
        
        return 0
    }
}

//extension NSData{
//    class var declaredDatatype: String {
//        return Blob.declaredDatatype
//    }
//    class func fromDatatypeValue(blobValue: Blob) -> Self {
//        return self.init(bytes: blobValue.bytes, length: blobValue.bytes.count)
//    }
//    var datatypeValue: Blob {
//        return Blob(bytes: bytes, length: length)
//    }
//}