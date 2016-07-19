//
//  SQLDataHelperProtocol.swift
//  Pods
//
//  Created by Akash Desai on 7/18/16.
//
//

import Foundation

protocol SQLDataHelperProtocol {
    typealias T
    static func createTable() throws -> Void
    static func insert(item: T) throws -> Int64
    static func delete(item: T) throws -> Void
    static func findAll() throws -> [T]?
}