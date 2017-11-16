//
//  DopamineConfiguration.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/7/17.
//

import Foundation

@objc
public class DopamineConfiguration : NSObject, NSCoding {
    
    @objc public static var current: DopamineConfiguration { get { return DopaminePropertiesControl.current.configuration } }
    
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
    
    public func encode(with aCoder: NSCoder) {
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
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        if let configID = aDecoder.value(forKey: #keyPath(DopamineConfiguration.configID)) as? String?,
            let reinforcementEnabled = aDecoder.value(forKey: #keyPath(DopamineConfiguration.reinforcementEnabled)) as? Bool,
            let triggerEnabled = aDecoder.value(forKey: #keyPath(DopamineConfiguration.triggerEnabled)) as? Bool,
            let trackingEnabled = aDecoder.value(forKey: #keyPath(DopamineConfiguration.trackingEnabled)) as? Bool,
            let applicationState = aDecoder.value(forKey: #keyPath(DopamineConfiguration.applicationState)) as? Bool,
            let applicationViews = aDecoder.value(forKey: #keyPath(DopamineConfiguration.applicationViews)) as? Bool,
            let customViews = aDecoder.value(forKey: #keyPath(DopamineConfiguration.customViews)) as? [String: Any],
            let customEvents = aDecoder.value(forKey: #keyPath(DopamineConfiguration.customEvents)) as? [String: Any],
            let notificationObservations = aDecoder.value(forKey: #keyPath(DopamineConfiguration.notificationObservations)) as? Bool,
            let storekitObservations = aDecoder.value(forKey: #keyPath(DopamineConfiguration.storekitObservations)) as? Bool,
            let locationObservations = aDecoder.value(forKey: #keyPath(DopamineConfiguration.locationObservations)) as? Bool,
            let trackBatchSize = aDecoder.value(forKey: #keyPath(DopamineConfiguration.trackBatchSize)) as? Int,
            let reportBatchSize = aDecoder.value(forKey: #keyPath(DopamineConfiguration.reportBatchSize)) as? Int,
            let integrationMethod = aDecoder.value(forKey: #keyPath(DopamineConfiguration.integrationMethod)) as? String,
            let advertiserID = aDecoder.value(forKey: #keyPath(DopamineConfiguration.configID)) as? Bool,
            let consoleLoggingEnabled = aDecoder.value(forKey: #keyPath(DopamineConfiguration.configID)) as? Bool {
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
    
    // test config
    static var standard: DopamineConfiguration {
        
        var customEvents: [String: [String:String]] = [:]
        customEvents["UIButton-DopamineKit_Example.ViewController-action2Performed"] = ["sender":"UIButton",
                             "target":"DopamineKit_Example.ViewController",
                             "selector":"action2Performed"]
        
        let customViews = ["DopamineKit_Example.ViewController": "DopamineKit_Example.ViewController",
                           "LayerPlayer.ClassListViewController": "LayerPlayer.ClassListViewController"
                           ]
        
        var standardConfig: [String: Any] = [:]
        standardConfig["configID"] = nil
        standardConfig["reinforcementEnabled"] = true
        standardConfig["triggerEnabled"] = false
        standardConfig["trackingEnabled"] = true
        standardConfig["trackingCapabilities"] = ["applicationState": true,
                                                  "applicationViews": true,
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
        
        return DopamineConfiguration.convert(configDictionary: standardConfig)!
    }
    
}

extension DopamineConfiguration {
    static func convert(configDictionary: [String: Any]) -> DopamineConfiguration? {
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
        } else {
            DopeLog.error("could not convert Config dictionary")
            return nil
        }
    }
}

