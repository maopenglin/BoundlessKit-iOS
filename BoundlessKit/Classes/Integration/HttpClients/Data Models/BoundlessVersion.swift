//
//  BoundlessVersion.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

internal struct BoundlessVersion {
    
    let name: String?
    let mappings: [String: [String: Any]]
    
    init(_ name: String? = nil,
         _ mappings: [String: [String: Any]] = [:]) {
        self.name = name
        self.mappings = mappings
    }
}

extension BoundlessVersion {
    init?(data: Data) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        defer {
            unarchiver.finishDecoding()
        }
        guard let versionID = unarchiver.decodeObject(forKey: "versionID") as? String? else { return nil }
        guard let mappings = unarchiver.decodeObject(forKey: "mappings") as? [String: [String: Any]] else { return nil }
        self.init(versionID, mappings)
    }
    
    func encode() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(name, forKey: "versionID")
        archiver.encode(mappings, forKey: "mappings")
        archiver.finishEncoding()
        return data as Data
    }
}

extension BoundlessVersion {
    static func convert(from dict: [String: Any]) -> BoundlessVersion? {
        guard let versionID = dict["versionID"] as? String else { BKLog.debug(error: "Bad parameter"); return nil }
        let mappings = dict["mappings"] as? [String: [String: Any]] ?? [:]
        
        return BoundlessVersion.init(
            versionID,
            mappings
        )
    }
}
