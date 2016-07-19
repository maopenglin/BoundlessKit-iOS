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
    index: Int64?,
    actionID: String?,
    reinforcementID: String?,
    //    metaData: NSData?,
    utc: Int64?,
    timezoneOffset: Int64?
)


class SQLReportedActionDataHelper : SQLDataHelperProtocol {
    
    static let TABLE_NAME = "Reinforced_Actions"
    
    static let table = Table(TABLE_NAME)
    static let index = Expression<Int64>("index")
    static let actionID = Expression<String>("actionid")
    static let reinforcementID = Expression<String>("reinforcementid")
    //    static let metaData = Expression<SQLite.Blob>("metadata")
    static let utc = Expression<Int64>("utc")
    static let timezoneOffset = Expression<Int64>("timezoneoffset")
    
    typealias T = SQLReportedAction
    
    static func createTable() throws {
        guard let DB = SQLiteDataStore.instance.DDB else {
            throw SQLDataAccessError.Datastore_Connection_Error
        }
        do {
            let _ = try DB.run( table.create(ifNotExists: true) {t in
                t.column(index, primaryKey: true)
                t.column(actionID)
                t.column(reinforcementID)
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
        guard let DB = SQLiteDataStore.instance.DDB
        else { throw SQLDataAccessError.Datastore_Connection_Error }
        
        if (item.actionID != nil && item.reinforcementID != nil && item.utc != nil && item.timezoneOffset != nil) {
            let insert = table.insert(actionID <- item.actionID!, reinforcementID <- item.reinforcementID!, utc <- item.utc!, timezoneOffset <- item.timezoneOffset!)
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
            DopamineKit.DebugLog("Invalid reinforced action values: actionID:(\(item.actionID)) reinforcementID:(\(item.reinforcementID)) utc:(\(item.utc)) timezoneOffset:(\(item.timezoneOffset))")
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
                return SQLReportedAction(index: item[index] , actionID: item[actionID], reinforcementID: item[reinforcementID], utc: item[utc], timezoneOffset: item[timezoneOffset])
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
                results.append(SQLReportedAction(index: item[index] , actionID: item[actionID], reinforcementID: item[reinforcementID], utc: item[utc], timezoneOffset: item[timezoneOffset]))
            }
        } catch {
            throw SQLDataAccessError.Search_Error
        }
        
        return results
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