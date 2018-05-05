//
//  BoundlessUserIdentity.swift
//  BoundlessKit
//
//  Created by Akash Desai on 5/4/18.
//

import Foundation

protocol BoundlessUserIdentityCustomSource : class {
    func idForBoundless() -> String?
}

open class BoundlessUserIdentity : NSObject {
    enum Source {
        case advertiser, vendor, custom
    }
    
    weak static var sourceDelegate: BoundlessUserIdentityCustomSource?
    static var source: Source = .vendor {
        didSet {
            _value = nil
            _ = value
        }
    }
    
    class func setCustom(_ newId:String?) {
//        if let validId = newId?.asValidId ?? _value ?? BoundlessKey.load(key: NSStringFromClass(BoundlessUserIdentity.self)) {
//            value = validId
//        }
        value = newId?.asValidId ?? _value ?? BoundlessKey.load(key: NSStringFromClass(BoundlessUserIdentity.self)) ?? UUID().uuidString
    }
    
    fileprivate static var _value: String?
    static var value: String {
        get {
            switch source {
            case .advertiser:
                _value = ASIdHelper.adId()?.uuidString
                if _value != nil {
                    return _value!
                }
                fallthrough
            case .vendor:
                _value = UIDevice.current.identifierForVendor?.uuidString
                if _value != nil {
                    return _value!
                }
                fallthrough
            case .custom:
                setCustom(sourceDelegate?.idForBoundless())
                if _value != nil {
                    return _value!
                }
                fallthrough
            default:
                return "IDUnavailable"
            }
        }
        set {
            if source == .custom {
                _value = newValue
                BoundlessKey.save(key: NSStringFromClass(BoundlessUserIdentity.self), string: newValue)
            }
        }
    }
}

extension String {
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
