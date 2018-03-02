//
//  DopamineConfiguration.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/7/17.
//

import Foundation

@objc
public class DopamineConfiguration : DopamineDefaultsSingleton  {
    
    public enum IntegrationMethodType : String {
        case manual, codeless
    }
    
    @objc
    public internal(set) static var current: DopamineConfiguration = { return DopamineDefaults.current.unarchive() ?? DopamineConfiguration() }()
        {
        didSet {
            DopamineDefaults.current.archive(current)
        }
    }
    
    @objc public let configID: String?
    
    @objc public let reinforcementEnabled: Bool
    @objc public let reportBatchSize: Int
    
    @objc public let triggerEnabled: Bool
    
    @objc public let trackingEnabled: Bool
    @objc public let trackBatchSize: Int
    
    @objc public let integrationMethod: String
    public var integrationMethodType: IntegrationMethodType {
        get {
            return IntegrationMethodType.init(rawValue: integrationMethod) ?? .manual
        }
    }
    
    @objc public let advertiserID: Bool
    @objc public let consoleLoggingEnabled: Bool
    
    @objc public let notificationObservations: Bool
    @objc public let storekitObservations: Bool
    @objc public let locationObservations: Bool
    @objc public let applicationState: Bool
    @objc public let applicationViews: Bool
    @objc public let customViews: [String: Any]
    @objc public let customEvents: [String: Any]
    
    
    init(configID: String? = nil,
         reinforcementEnabled: Bool = true,
         triggerEnabled: Bool = false,
         trackingEnabled: Bool = true,
         applicationState: Bool = true,
         applicationViews: Bool = true,
         customViews: [String: Any] = [:],
         customEvents: [String: Any] = [:],
         notificationObservations: Bool = false,
         storekitObservations: Bool = false,
         locationObservations: Bool = false,
         trackBatchSize: Int = 15,
         reportBatchSize: Int = 15,
         integrationMethod: String = "codeless",
         advertiserID: Bool = true,
         consoleLoggingEnabled: Bool = true
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
        guard let configID = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.configID)) as? String?,
            let customViews = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.customViews)) as? [String: Any],
            let customEvents = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.customEvents)) as? [String: Any],
            let integrationMethod = aDecoder.decodeObject(forKey: #keyPath(DopamineConfiguration.integrationMethod)) as? String else {
                return nil
        }
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
    }
    
}

extension DopamineConfiguration {
    static func convert(from dict: [String: Any]) -> DopamineConfiguration? {
        guard let configID = dict["configID"] as? String? else { DopeLog.debug("Bad parameter"); return nil }
        guard let reinforcementEnabled = dict["reinforcementEnabled"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let triggerEnabled = dict["triggerEnabled"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let trackingEnabled = dict["trackingEnabled"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let trackingCapabilities = dict["trackingCapabilities"] as? [String: Any] else { DopeLog.debug("Bad parameter"); return nil }
        guard let applicationState = trackingCapabilities["applicationState"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let applicationViews = trackingCapabilities["applicationViews"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let customViews = trackingCapabilities["customViews"] as? [String: Any] else { DopeLog.debug("Bad parameter"); return nil }
        guard let customEvents = trackingCapabilities["customEvents"] as? [String: Any] else { DopeLog.debug("Bad parameter"); return nil }
        guard let notificationObservations = trackingCapabilities["notificationObservations"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let storekitObservations = trackingCapabilities["storekitObservations"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let locationObservations = trackingCapabilities["locationObservations"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let batchSize = dict["batchSize"] as? [String: Any] else { DopeLog.debug("Bad parameter"); return nil }
        guard let trackBatchSize = batchSize["track"] as? Int else { DopeLog.debug("Bad parameter"); return nil }
        guard let reportBatchSize = batchSize["report"] as? Int else { DopeLog.debug("Bad parameter"); return nil }
        guard let integrationMethod = dict["integrationMethod"] as? String else { DopeLog.debug("Bad parameter"); return nil }
        guard let advertiserID = dict["advertiserID"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let consoleLoggingEnabled = dict["consoleLoggingEnabled"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        
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

