//
//  DopeConfig.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/7/17.
//

import Foundation


@objc
public class DopeConfig : NSObject, NSCoding {
    
    @objc public static var shared: DopeConfig {
        if let savedConfigData = DopeConfig.defaults.object(forKey: DopeConfig.defaultsKey) as? NSData,
            let savedConfig = NSKeyedUnarchiver.unarchiveObject(with: savedConfigData as Data) as? DopeConfig {
            return savedConfig
        } else {
            return DopeConfig()
        }
    }
    
    private static let defaults = UserDefaults.standard
    private static let defaultsKey = "DopamineConfiguration"
    
    @objc public var configID: String?
    
    @objc public var reinforcementEnabled: Bool
    @objc public var triggerEnabled: Bool
    @objc public var trackingEnabled: Bool
    
    @objc public var trackingCapabilities: [String: Any]
    @objc public var batchSize: [String: Any]
    
    @objc public var integrationMethod: String
    @objc public var advertiserID: Bool
    @objc public var consoleLoggingEnabled: Bool
    
    @objc public var trackingApplicationStateEnabled: Bool {
        get {
            return trackingCapabilities["applicationState"] as? Bool ?? true
        }
        set {
            trackingCapabilities["applicationState"] = newValue
        }
    }
    @objc public var trackingApplicationViewsEnabled: Bool {
        get {
            return trackingCapabilities["applicationViews"] as? Bool ?? true
        }
        set {
            trackingCapabilities["applicationViews"] = newValue
        }
    }
    @objc public var trackingCustomViews: [String] {
        get {
            return trackingCapabilities["customViews"] as? [String] ?? []
        }
        set {
            trackingCapabilities["customViews"] = newValue
        }
    }
    @objc public var trackingCustomEvents: [String: String] {
        get {
            return trackingCapabilities["customEvents"] as? [String: String] ?? [:]
        }
        set {
            trackingCapabilities["customEvents"] = newValue
        }
    }
    @objc public var trackingNotificationObservationsEnabled: Bool {
        get {
            return trackingCapabilities["notificationObservations"] as? Bool ?? true
        }
        set {
            trackingCapabilities["notificationObservations"] = newValue
        }
    }
    @objc public var trackingStorekitObservationsEnabled: Bool {
        get {
            return trackingCapabilities["storekitObservations"] as? Bool ?? true
        }
        set {
            trackingCapabilities["storekitObservations"] = newValue
        }
    }
    @objc public var trackingLocationObservationsEnabled: Bool {
        get {
            return trackingCapabilities["locationObservations"] as? Bool ?? true
        }
        set {
            trackingCapabilities["locationObservations"] = newValue
        }
    }
    @objc public var trackingBatchSize: Int {
        get {
            return batchSize["track"] as? Int ?? 20
        }
        set {
            batchSize["track"] = newValue
        }
    }
    @objc public var reportBatchSize: Int {
        get {
            return batchSize["report"] as? Int ?? 20
        }
        set {
            batchSize["report"] = newValue
        }
    }
    
    init(configID: String? = nil,
                  reinforcementEnabled: Bool = true,
                  triggerEnabled: Bool = false,
                  trackingEnabled: Bool = true,
                  trackingCapabilities: [String: Any] = ["applicationState": true,
                                                         "applicationViews": true,
                                                         "customViews": [String](),
                                                         "customEvents": [String: String](),
                                                         "notificationObservations": true,
                                                         "storekitObservations": true,
                                                         "locationObservations": true
                                                         ],
                  batchSize: [String: Any] = ["track": 20, "report": 20],
                  integrationMethod: String = "codeless",
                  advertiserID: Bool = true,
                  consoleLoggingEnabled: Bool = true
                  ) {
        self.configID = configID
        self.reinforcementEnabled = reinforcementEnabled
        self.triggerEnabled = triggerEnabled
        self.trackingEnabled = trackingEnabled
        self.trackingCapabilities = trackingCapabilities
        self.batchSize = batchSize
        self.integrationMethod = integrationMethod
        self.advertiserID = advertiserID
        self.consoleLoggingEnabled = consoleLoggingEnabled
        super.init()
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(configID, forKey: #keyPath(DopeConfig.configID))
        aCoder.encode(reinforcementEnabled, forKey: #keyPath(DopeConfig.reinforcementEnabled))
        aCoder.encode(triggerEnabled, forKey: #keyPath(DopeConfig.triggerEnabled))
        aCoder.encode(trackingEnabled, forKey: #keyPath(DopeConfig.trackingEnabled))
        aCoder.encode(trackingCapabilities, forKey: #keyPath(DopeConfig.trackingCapabilities))
        aCoder.encode(batchSize, forKey: #keyPath(DopeConfig.batchSize))
        aCoder.encode(integrationMethod, forKey: #keyPath(DopeConfig.integrationMethod))
        aCoder.encode(advertiserID, forKey: #keyPath(DopeConfig.advertiserID))
        aCoder.encode(consoleLoggingEnabled, forKey: #keyPath(DopeConfig.consoleLoggingEnabled))
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        self.init()
        if let configID = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? String? {
            self.configID = configID
        }
        if let reinforcementEnabled = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? Bool {
            self.reinforcementEnabled = reinforcementEnabled
        }
        if let triggerEnabled = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? Bool {
            self.triggerEnabled = triggerEnabled
        }
        if let trackingEnabled = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? Bool {
            self.trackingEnabled = trackingEnabled
        }
        if let trackingCapabilities = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? [String: Any] {
            self.trackingCapabilities = trackingCapabilities
        }
        if let batchSize = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? [String: Any] {
            self.batchSize = batchSize
        }
        if let integrationMethod = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? String {
            self.integrationMethod = integrationMethod
        }
        if let advertiserID = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? Bool {
            self.advertiserID = advertiserID
        }
        if let consoleLoggingEnabled = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? Bool {
            self.consoleLoggingEnabled = consoleLoggingEnabled
        }
    }
    

}

