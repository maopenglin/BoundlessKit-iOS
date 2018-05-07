//
//  BoundlessUserIdentity.swift
//  BoundlessKit
//
//  Created by Akash Desai on 5/4/18.
//

import Foundation

open class BoundlessUserIdentity : NSObject {
    enum Source : String {
        case IDFA, IDFV, custom
    }
    
    var source: Source = .IDFV {
        didSet {
            BKLog.print(error: "SOurce changed to:\(source)")
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
            BoundlessKey.buid = newId
        }
        source = .custom
    }
    
    fileprivate var _value: String?
    var value: String {
        get {
            switch source {
            case .IDFA:
                if _value == nil {
                    _value = ASIdHelper.adId()?.uuidString
                }
                fallthrough
            case .IDFV:
                if _value == nil {
                    _value = UIDevice.current.identifierForVendor?.uuidString
                }
                fallthrough
            case .custom:
                if _value == nil {
                    _value = _customSource ?? BoundlessKey.buid ?? {
                        let uuid = UUID().uuidString
                        _customSource = uuid
                        BoundlessKey.buid = uuid
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
