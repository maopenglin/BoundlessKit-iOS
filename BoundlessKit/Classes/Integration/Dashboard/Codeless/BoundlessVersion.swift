//
//  BoundlessVersion.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

internal struct BoundlessVersion {
    
    let versionID: String?
    let mappings: [String: [String: Any]]
    
    init(_ versionID: String? = nil,
         _ mappings: [String: [String: Any]] = [:]) {
        self.versionID = versionID
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
        archiver.encode(versionID, forKey: "versionID")
        archiver.encode(mappings, forKey: "mappings")
        archiver.finishEncoding()
        return data as Data
    }
}

extension BoundlessVersion {
    static func convert(from dict: [String: Any]) -> BoundlessVersion? {
        guard let versionID = dict["versionID"] as? String else { print("Bad parameter"); return nil }
        guard let mappings = dict["mappings"] as? [String: [String: Any]] else { print("Bad parameter"); return nil }
        
        return BoundlessVersion.init(
            versionID,
            mappings
        )
    }
}
