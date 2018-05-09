//
//  BoundlessKeychain.swift
//  BoundlessKit
//
//  Created by Akash Desai on 5/4/18.
//

import Foundation

internal class BoundlessKeychain {
    class var buid: String? {
        get {
            return BoundlessKeychain.load(key: NSStringFromClass(BoundlessUserIdentity.self))
        }
        set {
            if let newValue = newValue {
                BoundlessKeychain.save(key: NSStringFromClass(BoundlessUserIdentity.self), string: newValue)
            } else {
                BoundlessKeychain.clear(key: NSStringFromClass(BoundlessUserIdentity.self))
            }
        }
    }
}

extension BoundlessKeychain {
    class func save(key: String, data: Data) -> Bool {
        let query: [String : Any] = [ kSecClass as String       : kSecClassGenericPassword as String,
                                      kSecAttrAccount as String : key,
                                      kSecValueData as String   : data ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    class func save(key: String, string: String) {
        if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            _ = save(key: key, data: data)
//            BKLog.debug("Saved key:\(key) value:\(string)")
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
    
    class func load(key: String) -> String? {
        if let data: Data = BoundlessKeychain.load(key: key),
            let str = String(data: data, encoding: String.Encoding.utf8) {
//            BKLog.debug("Loaded key:\(key) with value:\(str)")
            return str
        } else {
//            BKLog.debug("Load failed for key:\(key)")
            return nil
        }
    }
    
    class func clear(key: String) {
        let query: [String : Any] = [ kSecClass as String       : kSecClassGenericPassword,
                                      kSecAttrAccount as String : key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
