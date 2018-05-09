//
//  BoundlessUserIdentity.swift
//  BoundlessKit
//
//  Created by Akash Desai on 5/4/18.
//

import Foundation

internal class BoundlessUserIdentity : NSObject {
    enum Source : String {
        case idfa, idfv, custom
    }
    
    var source: Source = .idfv {
        didSet {
            _value = nil
            _ = self.value
        }
    }
    
    func setSource() {
        source = { source }()
    }
    
    fileprivate var _customSource: String?
    func setSource(customValue newId:String?) {
        if let newId = newId?.asValidId {
            _customSource = newId
            BoundlessKeychain.buid = newId
        }
        source = .custom
    }
    
    fileprivate var _value: String?
    var value: String {
        get {
            switch source {
            case .idfa:
                if _value == nil {
                    _value = ASIdHelper.adId()?.uuidString.asValidId
                }
                fallthrough
            case .idfv:
                if _value == nil {
                    _value = UIDevice.current.identifierForVendor?.uuidString
                }
                fallthrough
            case .custom:
                if _value == nil {
                    _value = _customSource ?? BoundlessKeychain.buid ?? {
                        let uuid = UUID().uuidString
                        _customSource = uuid
                        BoundlessKeychain.buid = uuid
                        return uuid
                    }()
                }
                fallthrough
            default:
                return _value ?? "IDUnavailable"
            }
        }
    }
}

fileprivate extension String {
    var asValidId: String? {
        if !self.isEmpty,
            self.count <= 36,
            self != "00000000-0000-0000-0000-000000000000",
            self.range(of: "[^a-zA-Z0-9\\-]", options: .regularExpression) == nil {
            return self
        }
        return nil
    }
}
