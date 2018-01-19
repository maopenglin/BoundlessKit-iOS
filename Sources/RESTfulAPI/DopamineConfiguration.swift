//
//  DopamineConfiguration.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/7/17.
//

import Foundation

@objc
public class DopamineConfiguration : UserDefaultsSingleton  {
    
    @objc
    public static var current: DopamineConfiguration = {
        return UserDefaults.dopamine.unarchive() ?? DopamineConfiguration.standard
        }()
        {
        didSet {
            UserDefaults.dopamine.archive(current)
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
    
    static func initStandard(with configID: String?) -> DopamineConfiguration {
        let standard = DopamineConfiguration.standard
        standard.configID = configID
        return standard
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(configID, forKey: #keyPath(DopamineConfiguration.configID))
        aCoder.encode(reinforcementEnabled, forKey: #keyPath(DopamineConfiguration.reinforcementEnabled))
        aCoder.encode(triggerEnabled, forKey: #keyPath(DopamineConfiguration.triggerEnabled))
        aCoder.encode(trackingEnabled, forKey: #keyPath(DopamineConfiguration.trackingEnabled))
        aCoder.encode(applicationState, forKey: #keyPath(DopamineConfiguration.applicationState))
        aCoder.encode(applicationViews, forKey: #keyPath(DopamineConfiguration.applicationViews))
        aCoder.encode(customViews, forKey: #keyPath(DopamineConfiguration.customViews))
        aCoder.encode(customEvents, forKey: #keyPath(DopamineConfiguration.customEvents))
        aCoder.encode(notificationObservations, forKey: #keyPath(DopamineConfiguration.notificationObservations))
        aCoder.encode(storekitObservations, forKey: #keyPath(DopamineConfiguration.storekitObservations))
        aCoder.encode(locationObservations, forKey: #keyPath(DopamineConfiguration.locationObservations))
        aCoder.encode(trackBatchSize, forKey: #keyPath(DopamineConfiguration.trackBatchSize))
        aCoder.encode(reportBatchSize, forKey: #keyPath(DopamineConfiguration.reportBatchSize))
        aCoder.encode(integrationMethod, forKey: #keyPath(DopamineConfiguration.integrationMethod))
        aCoder.encode(advertiserID, forKey: #keyPath(DopamineConfiguration.advertiserID))
        aCoder.encode(consoleLoggingEnabled, forKey: #keyPath(DopamineConfiguration.consoleLoggingEnabled))
//        DopeLog.debug("Saved DopamineConfiguration to user defaults.")
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        if let configID = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.configID)) as? String?,
//            let reinforcementEnabled = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.reinforcementEnabled)) as? Bool,
//            let triggerEnabled = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.triggerEnabled)) as? Bool,
//            let trackingEnabled = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.trackingEnabled)) as? Bool,
//            let applicationState = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.applicationState)) as? Bool,
//            let applicationViews = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.applicationViews)) as? Bool,
            let customViews = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.customViews)) as? [String: Any],
            let customEvents = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.customEvents)) as? [String: Any],
//            let notificationObservations = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.notificationObservations)) as? Bool,
//            let storekitObservations = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.storekitObservations)) as? Bool,
//            let locationObservations = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.locationObservations)) as? Bool,
//            let trackBatchSize = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.trackBatchSize)) as? Int,
//            let reportBatchSize = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.reportBatchSize)) as? Int,
            let integrationMethod = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.integrationMethod)) as? String
//            let advertiserID = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.advertiserID)) as? Bool,
//            let consoleLoggingEnabled = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.consoleLoggingEnabled)) as? Bool
        {
            self.init(
                configID: configID,
                reinforcementEnabled: aDecoder.decodeBool(forKey: #keyPath(DopamineConfiguration.reinforcementEnabled)),
                triggerEnabled: aDecoder.decodeBool(forKey: #keyPath(DopamineConfiguration.triggerEnabled)),
                trackingEnabled: aDecoder.decodeBool(forKey: #keyPath(DopamineConfiguration.trackingEnabled)),
                applicationState: aDecoder.decodeBool(forKey: #keyPath(DopamineConfiguration.applicationState)),
                applicationViews: aDecoder.decodeBool(forKey: #keyPath(DopamineConfiguration.applicationViews)),
                customViews: customViews,
                customEvents: customEvents,
                notificationObservations: aDecoder.decodeBool(forKey: #keyPath(DopamineConfiguration.notificationObservations)),
                storekitObservations: aDecoder.decodeBool(forKey: #keyPath(DopamineConfiguration.storekitObservations)),
                locationObservations: aDecoder.decodeBool(forKey: #keyPath(DopamineConfiguration.locationObservations)),
                trackBatchSize: aDecoder.decodeInteger(forKey: #keyPath(DopamineConfiguration.trackBatchSize)),
                reportBatchSize: aDecoder.decodeInteger(forKey: #keyPath(DopamineConfiguration.reportBatchSize)),
                integrationMethod: integrationMethod,
                advertiserID: aDecoder.decodeBool(forKey: #keyPath(DopamineConfiguration.advertiserID)),
                consoleLoggingEnabled: aDecoder.decodeBool(forKey: #keyPath(DopamineConfiguration.consoleLoggingEnabled))
            )
        } else {
            return nil
        }
    }
    
    // test config
    static var standard: DopamineConfiguration = {
        
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
        
        
        return DopamineConfiguration.convert(from: standardConfig)!
    }()
    
}

extension DopamineConfiguration {
    static func convert(from configDictionary: [String: Any]) -> DopamineConfiguration? {
        guard let configID = configDictionary["configID"] as? String? else { DopeLog.debug("Bad parameter"); return nil }
        guard let reinforcementEnabled = configDictionary["reinforcementEnabled"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let triggerEnabled = configDictionary["triggerEnabled"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let trackingEnabled = configDictionary["trackingEnabled"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let trackingCapabilities = configDictionary["trackingCapabilities"] as? [String: Any] else { DopeLog.debug("Bad parameter"); return nil }
        guard let applicationState = trackingCapabilities["applicationState"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let applicationViews = trackingCapabilities["applicationViews"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let customViews = trackingCapabilities["customViews"] as? [String: Any] else { DopeLog.debug("Bad parameter"); return nil }
        guard let customEvents = trackingCapabilities["customEvents"] as? [String: Any] else { DopeLog.debug("Bad parameter"); return nil }
        guard let notificationObservations = trackingCapabilities["notificationObservations"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let storekitObservations = trackingCapabilities["storekitObservations"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let locationObservations = trackingCapabilities["locationObservations"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let batchSize = configDictionary["batchSize"] as? [String: Any] else { DopeLog.debug("Bad parameter"); return nil }
        guard let trackBatchSize = batchSize["track"] as? Int else { DopeLog.debug("Bad parameter"); return nil }
        guard let reportBatchSize = batchSize["report"] as? Int else { DopeLog.debug("Bad parameter"); return nil }
        guard let integrationMethod = configDictionary["integrationMethod"] as? String else { DopeLog.debug("Bad parameter"); return nil }
        guard let advertiserID = configDictionary["advertiserID"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let consoleLoggingEnabled = configDictionary["consoleLoggingEnabled"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        
        return DopamineConfiguration.init(
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

