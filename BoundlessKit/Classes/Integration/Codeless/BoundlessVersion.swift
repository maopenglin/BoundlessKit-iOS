//
//  BoundlessVersion.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

internal struct BoundlessVersion {
    
    let versionID: String?
    let mappings: [String: [String]]
    
    init(_ versionID: String?,
         _ mappings: [String: [String]]) {
        self.versionID = versionID
        self.mappings = mappings
    }
}

extension BoundlessVersion {
    func encode() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(versionID, forKey: "versionID")
        archiver.encode(mappings, forKey: "mappings")
        archiver.finishEncoding()
        return data as Data
    }
    
    init?(data: Data) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        defer {
            unarchiver.finishDecoding()
        }
        guard let versionID = unarchiver.decodeObject(forKey: "versionID") as? String? else { return nil }
        guard let mappings = unarchiver.decodeObject(forKey: "mappings") as? [String: [String]] else { return nil }
        self.init(versionID, mappings)
    }
}
