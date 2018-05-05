//
//  BoundlessKeys.swift
//  BoundlessKit
//
//  Created by Akash Desai on 5/4/18.
//

import Foundation

public class BoundlessKey {
    
}

extension BoundlessKey {
    class func save(key: String, data: Data) -> Bool {
        let query: [String : Any] = [ kSecClass as String       : kSecClassGenericPassword as String,
                                      kSecAttrAccount as String : key,
                                      kSecValueData as String   : data ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    public
    class func save(key: String, string: String) {
        if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            _ = save(key: key, data: data)
        }
    }
    
    class func load(key: String) -> Data? {
        let query: [String : Any] = [ kSecClass as String       : kSecClassGenericPassword,
                                      kSecAttrAccount as String : key,
                                      kSecReturnData as String  : kCFBooleanTrue,
                                      kSecMatchLimit as String  : kSecMatchLimitOne ]
        var resultRef: CFTypeRef? = nil
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &resultRef)
        return (status == errSecSuccess) ? (resultRef as! Data?) : nil
    }
    public
    class func load(key: String) -> String? {
        if let data: Data = BoundlessKey.load(key: key),
            let str = String(data: data, encoding: String.Encoding.utf8) {
            return str
        } else {
            return nil
        }
    }
    public
    class func clear(key: String) {
        let query: [String : Any] = [ kSecClass as String       : kSecClassGenericPassword,
                                      kSecAttrAccount as String : key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
