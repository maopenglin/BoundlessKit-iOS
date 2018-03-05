//
//  BoundlessConfiguration.swift
//  BoundlessKit
//
//  Created by Akash Desai on 11/7/17.
//

import Foundation

@objc
public class BoundlessConfiguration : UserDefaultsSingleton  {
    
    @objc
    public static var current: BoundlessConfiguration = {
        return UserDefaults.boundless.unarchive() ?? BoundlessConfiguration.standard
        }()
        {
        didSet {
            UserDefaults.boundless.archive(current)
        }
    }
    
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
    
    static func initStandard(with configID: String?) -> BoundlessConfiguration {
        let standard = BoundlessConfiguration.standard
        standard.configID = configID
        return standard
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(configID, forKey: #keyPath(BoundlessConfiguration.configID))
        aCoder.encode(reinforcementEnabled, forKey: #keyPath(BoundlessConfiguration.reinforcementEnabled))
        aCoder.encode(triggerEnabled, forKey: #keyPath(BoundlessConfiguration.triggerEnabled))
        aCoder.encode(trackingEnabled, forKey: #keyPath(BoundlessConfiguration.trackingEnabled))
        aCoder.encode(applicationState, forKey: #keyPath(BoundlessConfiguration.applicationState))
        aCoder.encode(applicationViews, forKey: #keyPath(BoundlessConfiguration.applicationViews))
        aCoder.encode(customViews, forKey: #keyPath(BoundlessConfiguration.customViews))
        aCoder.encode(customEvents, forKey: #keyPath(BoundlessConfiguration.customEvents))
        aCoder.encode(notificationObservations, forKey: #keyPath(BoundlessConfiguration.notificationObservations))
        aCoder.encode(storekitObservations, forKey: #keyPath(BoundlessConfiguration.storekitObservations))
        aCoder.encode(locationObservations, forKey: #keyPath(BoundlessConfiguration.locationObservations))
        aCoder.encode(trackBatchSize, forKey: #keyPath(BoundlessConfiguration.trackBatchSize))
        aCoder.encode(reportBatchSize, forKey: #keyPath(BoundlessConfiguration.reportBatchSize))
        aCoder.encode(integrationMethod, forKey: #keyPath(BoundlessConfiguration.integrationMethod))
        aCoder.encode(advertiserID, forKey: #keyPath(BoundlessConfiguration.advertiserID))
        aCoder.encode(consoleLoggingEnabled, forKey: #keyPath(BoundlessConfiguration.consoleLoggingEnabled))
//        BoundlessLog.debug("Saved BoundlessConfiguration to user defaults.")
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        if let configID = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.configID)) as? String?,
//            let reinforcementEnabled = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.reinforcementEnabled)) as? Bool,
//            let triggerEnabled = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.triggerEnabled)) as? Bool,
//            let trackingEnabled = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.trackingEnabled)) as? Bool,
//            let applicationState = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.applicationState)) as? Bool,
//            let applicationViews = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.applicationViews)) as? Bool,
            let customViews = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.customViews)) as? [String: Any],
            let customEvents = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.customEvents)) as? [String: Any],
//            let notificationObservations = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.notificationObservations)) as? Bool,
//            let storekitObservations = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.storekitObservations)) as? Bool,
//            let locationObservations = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.locationObservations)) as? Bool,
//            let trackBatchSize = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.trackBatchSize)) as? Int,
//            let reportBatchSize = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.reportBatchSize)) as? Int,
            let integrationMethod = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.integrationMethod)) as? String
//            let advertiserID = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.advertiserID)) as? Bool,
//            let consoleLoggingEnabled = aDecoder.decodeObject(forKey: #keyPath(BoundlessConfiguration.consoleLoggingEnabled)) as? Bool
        {
            self.init(
                configID: configID,
                reinforcementEnabled: aDecoder.decodeBool(forKey: #keyPath(BoundlessConfiguration.reinforcementEnabled)),
                triggerEnabled: aDecoder.decodeBool(forKey: #keyPath(BoundlessConfiguration.triggerEnabled)),
                trackingEnabled: aDecoder.decodeBool(forKey: #keyPath(BoundlessConfiguration.trackingEnabled)),
                applicationState: aDecoder.decodeBool(forKey: #keyPath(BoundlessConfiguration.applicationState)),
                applicationViews: aDecoder.decodeBool(forKey: #keyPath(BoundlessConfiguration.applicationViews)),
                customViews: customViews,
                customEvents: customEvents,
                notificationObservations: aDecoder.decodeBool(forKey: #keyPath(BoundlessConfiguration.notificationObservations)),
                storekitObservations: aDecoder.decodeBool(forKey: #keyPath(BoundlessConfiguration.storekitObservations)),
                locationObservations: aDecoder.decodeBool(forKey: #keyPath(BoundlessConfiguration.locationObservations)),
                trackBatchSize: aDecoder.decodeInteger(forKey: #keyPath(BoundlessConfiguration.trackBatchSize)),
                reportBatchSize: aDecoder.decodeInteger(forKey: #keyPath(BoundlessConfiguration.reportBatchSize)),
                integrationMethod: integrationMethod,
                advertiserID: aDecoder.decodeBool(forKey: #keyPath(BoundlessConfiguration.advertiserID)),
                consoleLoggingEnabled: aDecoder.decodeBool(forKey: #keyPath(BoundlessConfiguration.consoleLoggingEnabled))
            )
        } else {
            return nil
        }
    }
    
    // test config
    static var standard: BoundlessConfiguration = {
        
        var standardConfig: [String: Any] = [:]
        standardConfig["configID"] = nil
        standardConfig["reinforcementEnabled"] = true
        standardConfig["triggerEnabled"] = false
        standardConfig["trackingEnabled"] = true
        standardConfig["trackingCapabilities"] = ["applicationState": true,
                                                  "applicationViews": true,
                                                  "customViews": [String: Any](),
                                                  "customEvents": [String: Any](),
                                                  "notificationObservations": false,
                                                  "storekitObservations": false,
                                                  "locationObservations": true
        ]
        standardConfig["batchSize"] = ["track": 15, "report": 15]
        standardConfig["integrationMethod"] = "codeless"
        standardConfig["advertiserID"] = true
        standardConfig["consoleLoggingEnabled"] = true
        
        
        return BoundlessConfiguration.convert(from: standardConfig)!
    }()
    
}

extension BoundlessConfiguration {
    static func convert(from configDictionary: [String: Any]) -> BoundlessConfiguration? {
        guard let configID = configDictionary["configID"] as? String? else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let reinforcementEnabled = configDictionary["reinforcementEnabled"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let triggerEnabled = configDictionary["triggerEnabled"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let trackingEnabled = configDictionary["trackingEnabled"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let trackingCapabilities = configDictionary["trackingCapabilities"] as? [String: Any] else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let applicationState = trackingCapabilities["applicationState"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let applicationViews = trackingCapabilities["applicationViews"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let customViews = trackingCapabilities["customViews"] as? [String: Any] else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let customEvents = trackingCapabilities["customEvents"] as? [String: Any] else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let notificationObservations = trackingCapabilities["notificationObservations"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let storekitObservations = trackingCapabilities["storekitObservations"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let locationObservations = trackingCapabilities["locationObservations"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let batchSize = configDictionary["batchSize"] as? [String: Any] else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let trackBatchSize = batchSize["track"] as? Int else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let reportBatchSize = batchSize["report"] as? Int else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let integrationMethod = configDictionary["integrationMethod"] as? String else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let advertiserID = configDictionary["advertiserID"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let consoleLoggingEnabled = configDictionary["consoleLoggingEnabled"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        
        return BoundlessConfiguration.init(
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
    }
}

