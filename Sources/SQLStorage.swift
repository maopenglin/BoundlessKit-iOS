//
//  DopeStorage.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation
import SQLite



enum SQLiteError: ErrorType {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}



public class SQLStorage : NSObject{
    public static let instance: SQLStorage = SQLStorage()
    private override init() {
        super.init()
        
        do{
            let path = NSSearchPathForDirectoriesInDomains(
                .DocumentDirectory, .UserDomainMask, true
                ).first!
            
            
            let db = try Connection(path+"/dopamine")
            
            
            
            let users = Table("tracks")
            let id = Expression<Int64>("id")
            let actionID = Expression<String?>("actionid")
            let utc = Expression<String>("utc")
            let localTime = Expression<String>("localtime")
            
            try db.run(users.create { t in
                t.column(id, primaryKey: true)
                t.column(actionID)
                t.column(utc)
                t.column(localTime)
                })
            
            
            
            let stmt = try db.prepare("INSERT INTO tracks (email) VALUES (?)")
            for email in ["betty@icloud.com", "cathy@icloud.com"] {
                try stmt.run(email)
            }
            do{
                
                db.totalChanges    // 3
                db.changes         // 1
                db.lastInsertRowid // 3
                
                for row in try db.prepare("SELECT id, email FROM users") {
                    print("id: \(row[0]), email: \(row[1])")
                    // id: Optional(2), email: Optional("betty@icloud.com")
                    // id: Optional(3), email: Optional("cathy@icloud.com")
                }
                
                db.scalar("SELECT count(*) FROM users")
            } catch {
                DopamineKit.DebugLog("sql error:")
            }
        } catch {
            print("error opening database")
        }
        
    }
    
    static func writeTrack(event: DopeEvent){
        _ = self.instance
    }
    
    static func writeReinforcement(event: DopeEvent){
        _ = self.instance
    }
    
}