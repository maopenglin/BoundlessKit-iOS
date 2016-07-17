//
//  DopeStorage.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation
//import SQLite



enum SQLiteError: ErrorType {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

/** tbc
 
 
 
 
*/


internal class SQLStorage : NSObject{
    
    static let instance: SQLStorage = SQLStorage()
    private override init() {
        super.init()
    }
    
    
    static func writeTrack(event: DopeEvent){
        
    }
    
    static func writeReinforcement(event: DopeEvent){
        
    }
    
    
}