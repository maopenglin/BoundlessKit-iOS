//
//  SQLDataHelperProtocol.swift
//  Pods
//
//  Created by Akash Desai on 7/18/16.
//
//

import Foundation

protocol SQLDataHelperProtocol {
    associatedtype T
    static func createTable() -> Void
    static func dropTable() -> Void
    static func insert(_ item: T) -> Int64?
    static func delete(_ item: T) -> Void
    static func findAll() -> [T]
}
