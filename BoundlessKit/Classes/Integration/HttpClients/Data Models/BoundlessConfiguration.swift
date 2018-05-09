//
//  BoundlessConfiguration.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

internal struct BoundlessConfiguration {
    
    let configID: String?
    
    let integrationMethod: String
    let reinforcementEnabled: Bool
    let reportBatchSize: Int
    let triggerEnabled: Bool
    let trackingEnabled: Bool
    let trackBatchSize: Int
    
    var identityType: String
    let notificationObservations: Bool
    let storekitObservations: Bool
    let locationObservations: Bool
    let bluetoothObservations: Bool
    let applicationState: Bool
    let applicationViews: Bool
    let customViews: [String: Any]
    let customEvents: [String: Any]
    
    let consoleLoggingEnabled: Bool
    
    init(configID: String? = nil,
         integrationMethod: String = "manual",
         reinforcementEnabled: Bool = true,
         reportBatchSize: Int = 10,
         triggerEnabled: Bool = false,
         trackingEnabled: Bool = true,
         trackBatchSize: Int = 10,
         identityType: String = BoundlessUserIdentity.Source.idfv.rawValue,
         notificationObservations: Bool = false,
         storekitObservations: Bool = false,
         locationObservations: Bool = false,
         bluetoothObservations: Bool = true,
         applicationState: Bool = true,
         applicationViews: Bool = true,
         customViews: [String: Any] = [:],
         customEvents: [String: Any] = [:],
         consoleLoggingEnabled: Bool = true
        ) {
        self.configID = configID
        self.integrationMethod = integrationMethod
        self.reinforcementEnabled = reinforcementEnabled
        self.reportBatchSize = reportBatchSize
        self.triggerEnabled = triggerEnabled
        self.trackingEnabled = trackingEnabled
        self.trackBatchSize = trackBatchSize
        self.identityType = identityType
        self.notificationObservations = notificationObservations
        self.storekitObservations = storekitObservations
        self.locationObservations = locationObservations
        self.bluetoothObservations = bluetoothObservations
        self.applicationState = applicationState
        self.applicationViews = applicationViews
        self.customViews = customViews
        self.customEvents = customEvents
        self.consoleLoggingEnabled = consoleLoggingEnabled
    }
}

extension BoundlessConfiguration {
    func encode() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(configID, forKey: "configID")
        archiver.encode(integrationMethod, forKey: "integrationMethod")
        archiver.encode(reinforcementEnabled, forKey: "reinforcementEnabled")
        archiver.encode(reportBatchSize, forKey: "reportBatchSize")
        archiver.encode(triggerEnabled, forKey: "triggerEnabled")
        archiver.encode(trackingEnabled, forKey: "trackingEnabled")
        archiver.encode(trackBatchSize, forKey: "trackBatchSize")
        archiver.encode(identityType, forKey: "identityType")
        archiver.encode(notificationObservations, forKey: "notificationObservations")
        archiver.encode(storekitObservations, forKey: "storekitObservations")
        archiver.encode(locationObservations, forKey: "locationObservations")
        archiver.encode(bluetoothObservations, forKey: "bluetoothObservations")
        archiver.encode(applicationState, forKey: "applicationState")
        archiver.encode(applicationViews, forKey: "applicationViews")
        archiver.encode(customViews, forKey: "customViews")
        archiver.encode(customEvents, forKey: "customEvents")
        archiver.encode(consoleLoggingEnabled, forKey: "consoleLoggingEnabled")
        archiver.finishEncoding()
        return data as Data
    }
    
    init?(data: Data) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        defer {
            unarchiver.finishDecoding()
        }
        guard let configID = unarchiver.decodeObject(forKey: "configID") as? String else { return nil }
        guard let integrationMethod = unarchiver.decodeObject(forKey: "integrationMethod") as? String else { return nil }
        guard let identityType = unarchiver.decodeObject(forKey: "identityType") as? String else { return nil }
        guard let customViews = unarchiver.decodeObject(forKey: "customViews") as? [String: Any] else { return nil }
        guard let customEvents = unarchiver.decodeObject(forKey: "customEvents") as? [String: Any] else { return nil }
        self.init(configID: configID,
                  integrationMethod: integrationMethod,
                  reinforcementEnabled: unarchiver.decodeBool(forKey: "reinforcementEnabled"),
                  reportBatchSize: unarchiver.decodeInteger(forKey: "reportBatchSize"),
                  triggerEnabled: unarchiver.decodeBool(forKey: "triggerEnabled"),
                  trackingEnabled: unarchiver.decodeBool(forKey: "trackingEnabled"),
                  trackBatchSize: unarchiver.decodeInteger(forKey: "trackBatchSize"),
                  identityType: identityType,
                  notificationObservations: unarchiver.decodeBool(forKey: "notificationObservations"),
                  storekitObservations: unarchiver.decodeBool(forKey: "storekitObservations"),
                  locationObservations: unarchiver.decodeBool(forKey: "locationObservations"),
                  bluetoothObservations: unarchiver.decodeBool(forKey: "bluetoothObservations"),
                  applicationState: unarchiver.decodeBool(forKey: "applicationState"),
                  applicationViews: unarchiver.decodeBool(forKey: "applicationViews"),
                  customViews: customViews,
                  customEvents: customEvents,
                  consoleLoggingEnabled: unarchiver.decodeBool(forKey: "consoleLoggingEnabled")
        )
    }
}

extension BoundlessConfiguration {
    static func convert(from dict: [String: Any]) -> BoundlessConfiguration? {
        guard let configID = dict["configID"] as? String? else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let reinforcementEnabled = dict["reinforcementEnabled"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let triggerEnabled = dict["triggerEnabled"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let trackingEnabled = dict["trackingEnabled"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let trackingCapabilities = dict["trackingCapabilities"] as? [String: Any] else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let applicationState = trackingCapabilities["applicationState"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let applicationViews = trackingCapabilities["applicationViews"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let customViews = trackingCapabilities["customViews"] as? [String: Any] else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let customEvents = trackingCapabilities["customEvents"] as? [String: Any] else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let notificationObservations = trackingCapabilities["notificationObservations"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let storekitObservations = trackingCapabilities["storekitObservations"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let locationObservations = trackingCapabilities["locationObservations"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let bluetoothObservations = trackingCapabilities["bluetoothObservations"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let batchSize = dict["batchSize"] as? [String: Any] else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let trackBatchSize = batchSize["track"] as? Int else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let reportBatchSize = batchSize["report"] as? Int else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let integrationMethod = dict["integrationMethod"] as? String else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let advertiserID = dict["advertiserID"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let consoleLoggingEnabled = dict["consoleLoggingEnabled"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        
        return BoundlessConfiguration.init(configID: configID,
                                           integrationMethod: integrationMethod,
                                           reinforcementEnabled: reinforcementEnabled,
                                           reportBatchSize: reportBatchSize,
                                           triggerEnabled: triggerEnabled,
                                           trackingEnabled: trackingEnabled,
                                           trackBatchSize: trackBatchSize,
                                           identityType: advertiserID ? BoundlessUserIdentity.Source.idfa.rawValue : BoundlessUserIdentity.Source.idfv.rawValue,
                                           notificationObservations: notificationObservations,
                                           storekitObservations: storekitObservations,
                                           locationObservations: locationObservations,
                                           bluetoothObservations: bluetoothObservations,
                                           applicationState: applicationState,
                                           applicationViews: applicationViews,
                                           customViews: customViews,
                                           customEvents: customEvents,
                                           consoleLoggingEnabled: consoleLoggingEnabled
        )
    }
}
