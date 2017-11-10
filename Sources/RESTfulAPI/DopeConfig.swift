//
//  DopeConfig.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/7/17.
//

import Foundation


@objc
public class DopeConfig : NSObject {
    
    fileprivate static var _shared: DopeConfig?
    
    fileprivate static let defaults = UserDefaults.standard
    fileprivate static let defaultsKey = "DopamineConfiguration"
    
    @objc public var configID: String?
    
    @objc public var reinforcementEnabled: Bool
    @objc public var reportBatchSize: Int
    
    @objc public var triggerEnabled: Bool
    
    @objc public var trackingEnabled: Bool
    @objc public var trackBatchSize: Int
    
    @objc public var integrationMethod: String
    @objc public var advertiserID: Bool
    @objc public var consoleLoggingEnabled: Bool
    
    @objc public var notificationObservations: Bool
    @objc public var storekitObservations: Bool
    @objc public var locationObservations: Bool
    @objc public var applicationState: Bool
    @objc public var applicationViews: Bool
    @objc public var customViews: [String: Any]
    @objc public var customEvents: [String: Any]
    
    init(configID: String?,
                  reinforcementEnabled: Bool,
                  triggerEnabled: Bool,
                  trackingEnabled: Bool,
                  applicationState: Bool,
                  applicationViews: Bool,
                  customViews: [String: Any],
                  customEvents: [String: Any],
                  notificationObservations: Bool,
                  storekitObservations: Bool,
                  locationObservations: Bool,
                  trackBatchSize: Int,
                  reportBatchSize: Int,
                  integrationMethod: String,
                  advertiserID: Bool,
                  consoleLoggingEnabled: Bool
                  ) {
        self.configID = configID
        self.reinforcementEnabled = reinforcementEnabled
        self.triggerEnabled = triggerEnabled
        self.trackingEnabled = trackingEnabled
        self.applicationState = applicationState
        self.applicationViews = applicationViews
        self.customViews = customViews
        self.customEvents = customEvents
        self.notificationObservations = notificationObservations
        self.storekitObservations = storekitObservations
        self.locationObservations = locationObservations
        self.trackBatchSize = trackBatchSize
        self.reportBatchSize = reportBatchSize
        self.integrationMethod = integrationMethod
        self.advertiserID = advertiserID
        self.consoleLoggingEnabled = consoleLoggingEnabled
        super.init()
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        self.init(acoder: aDecoder)
    }
    
    // test config
    static var standard: DopeConfig {
        
        var customEvents: [String: [String:String]] = [:]
        customEvents["UIButton-DopamineKit_Example.ViewController-action2Performed"] = ["sender":"UIButton",
                             "target":"DopamineKit_Example.ViewController",
                             "selector":"action2Performed"]
        
        let customViews = ["DopamineKit_Example.ViewController": "DopamineKit_Example.ViewController",
                           "LayerPlayer.ClassListViewController": "LayerPlayer.ClassListViewController"
                           ]
        
        var standardConfig: [String: Any] = [:]
        standardConfig["configID"] = nil
        standardConfig["reinforcementEnabled"] = false
        standardConfig["triggerEnabled"] = false
        standardConfig["trackingEnabled"] = true
        standardConfig["trackingCapabilities"] = ["applicationState": false,
                                                  "applicationViews": false,
                                                  "customViews": customViews,
//                                                  "customViews": [String: Any](),
//                                                  "customEvents": [String: Any](),
                                                  "customEvents": customEvents,
                                                  "notificationObservations": false,
                                                  "storekitObservations": false,
                                                  "locationObservations": true
        ]
        standardConfig["batchSize"] = ["track": 15, "report": 15]
        standardConfig["integrationMethod"] = "codeless"
        standardConfig["advertiserID"] = true
        standardConfig["consoleLoggingEnabled"] = true
        
        return DopeConfig.convert(configDictionary: standardConfig)!
    }
    
}

extension DopeConfig {
    
    @objc public static var shared: DopeConfig {
        if let _shared = _shared {
            return _shared
        } else {
            _shared = retreive()
            return _shared!
        }
    }
    
    static func save(config: DopeConfig? = _shared) {
        DopeConfig.defaults.set(config, forKey: DopeConfig.defaultsKey)
        _shared = config
    }
    
    static func retreive() -> DopeConfig {
        if let _shared = _shared {
            return _shared
        } else if let savedConfigData = DopeConfig.defaults.object(forKey: DopeConfig.defaultsKey) as? NSData,
            let savedConfig = NSKeyedUnarchiver.unarchiveObject(with: savedConfigData as Data) as? DopeConfig {
            print("using saved dopamine configuration")
            return savedConfig
        } else {
            print("using standard dopamine configuration")
            return standard
        }
    }
    
    static func convert(configDictionary: [String: Any]) -> DopeConfig? {
        if let configID = configDictionary["configID"] as? String?,
            let reinforcementEnabled = configDictionary["reinforcementEnabled"] as? Bool,
            let triggerEnabled = configDictionary["triggerEnabled"] as? Bool,
            let trackingEnabled = configDictionary["trackingEnabled"] as? Bool,
            let trackingCapabilities = configDictionary["trackingCapabilities"] as? [String: Any],
            let applicationState = trackingCapabilities["applicationState"] as? Bool,
            let applicationViews = trackingCapabilities["applicationViews"] as? Bool,
            let customViews = trackingCapabilities["customViews"] as? [String: Any],
            let customEvents = trackingCapabilities["customEvents"] as? [String: Any],
            let notificationObservations = trackingCapabilities["notificationObservations"] as? Bool,
            let storekitObservations = trackingCapabilities["storekitObservations"] as? Bool,
            let locationObservations = trackingCapabilities["locationObservations"] as? Bool,
            let batchSize = configDictionary["batchSize"] as? [String: Any],
            let trackBatchSize = batchSize["track"] as? Int,
            let reportBatchSize = batchSize["report"] as? Int,
            let integrationMethod = configDictionary["integrationMethod"] as? String,
            let advertiserID = configDictionary["advertiserID"] as? Bool,
            let consoleLoggingEnabled = configDictionary["consoleLoggingEnabled"] as? Bool
        {
            return DopeConfig.init(
                configID: configID,
                reinforcementEnabled: reinforcementEnabled,
                triggerEnabled: triggerEnabled,
                trackingEnabled: trackingEnabled,
                applicationState: applicationState,
                applicationViews: applicationViews,
                customViews: customViews,
                customEvents: customEvents,
                notificationObservations: notificationObservations,
                storekitObservations: storekitObservations,
                locationObservations: locationObservations,
                trackBatchSize: trackBatchSize,
                reportBatchSize: reportBatchSize,
                integrationMethod: integrationMethod,
                advertiserID: advertiserID,
                consoleLoggingEnabled: consoleLoggingEnabled
            )
        } else {
            DopeLog.error("could not convert Config dictionary")
            return nil
        }
    }
}


extension DopeConfig : NSCoding {
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(configID, forKey: #keyPath(DopeConfig.configID))
        aCoder.encode(reinforcementEnabled, forKey: #keyPath(DopeConfig.reinforcementEnabled))
        aCoder.encode(triggerEnabled, forKey: #keyPath(DopeConfig.triggerEnabled))
        aCoder.encode(trackingEnabled, forKey: #keyPath(DopeConfig.trackingEnabled))
        aCoder.encode(applicationState, forKey: #keyPath(DopeConfig.applicationState))
        aCoder.encode(applicationViews, forKey: #keyPath(DopeConfig.applicationViews))
        aCoder.encode(customViews, forKey: #keyPath(DopeConfig.customViews))
        aCoder.encode(customEvents, forKey: #keyPath(DopeConfig.customEvents))
        aCoder.encode(notificationObservations, forKey: #keyPath(DopeConfig.notificationObservations))
        aCoder.encode(storekitObservations, forKey: #keyPath(DopeConfig.storekitObservations))
        aCoder.encode(locationObservations, forKey: #keyPath(DopeConfig.locationObservations))
        aCoder.encode(trackBatchSize, forKey: #keyPath(DopeConfig.trackBatchSize))
        aCoder.encode(reportBatchSize, forKey: #keyPath(DopeConfig.reportBatchSize))
        aCoder.encode(integrationMethod, forKey: #keyPath(DopeConfig.integrationMethod))
        aCoder.encode(advertiserID, forKey: #keyPath(DopeConfig.advertiserID))
        aCoder.encode(consoleLoggingEnabled, forKey: #keyPath(DopeConfig.consoleLoggingEnabled))
    }
    
    convenience public init?(acoder aDecoder: NSCoder) {
        if let configID = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? String?,
            let reinforcementEnabled = aDecoder.value(forKey: #keyPath(DopeConfig.reinforcementEnabled)) as? Bool,
            let triggerEnabled = aDecoder.value(forKey: #keyPath(DopeConfig.triggerEnabled)) as? Bool,
            let trackingEnabled = aDecoder.value(forKey: #keyPath(DopeConfig.trackingEnabled)) as? Bool,
            let applicationState = aDecoder.value(forKey: #keyPath(DopeConfig.applicationState)) as? Bool,
            let applicationViews = aDecoder.value(forKey: #keyPath(DopeConfig.applicationViews)) as? Bool,
            let customViews = aDecoder.value(forKey: #keyPath(DopeConfig.customViews)) as? [String: Any],
            let customEvents = aDecoder.value(forKey: #keyPath(DopeConfig.customEvents)) as? [String: Any],
            let notificationObservations = aDecoder.value(forKey: #keyPath(DopeConfig.notificationObservations)) as? Bool,
            let storekitObservations = aDecoder.value(forKey: #keyPath(DopeConfig.storekitObservations)) as? Bool,
            let locationObservations = aDecoder.value(forKey: #keyPath(DopeConfig.locationObservations)) as? Bool,
            let trackBatchSize = aDecoder.value(forKey: #keyPath(DopeConfig.trackBatchSize)) as? Int,
            let reportBatchSize = aDecoder.value(forKey: #keyPath(DopeConfig.reportBatchSize)) as? Int,
            let integrationMethod = aDecoder.value(forKey: #keyPath(DopeConfig.integrationMethod)) as? String,
            let advertiserID = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? Bool,
            let consoleLoggingEnabled = aDecoder.value(forKey: #keyPath(DopeConfig.configID)) as? Bool {
            self.init(
                configID: configID,
                reinforcementEnabled: reinforcementEnabled,
                triggerEnabled: triggerEnabled,
                trackingEnabled: trackingEnabled,
                applicationState: applicationState,
                applicationViews: applicationViews,
                customViews: customViews,
                customEvents: customEvents,
                notificationObservations: notificationObservations,
                storekitObservations: storekitObservations,
                locationObservations: locationObservations,
                trackBatchSize: trackBatchSize,
                reportBatchSize: reportBatchSize,
                integrationMethod: integrationMethod,
                advertiserID: advertiserID,
                consoleLoggingEnabled: consoleLoggingEnabled
            )
        } else {
            return nil
        }
    }
}
