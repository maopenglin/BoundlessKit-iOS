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
    
    let advertiserID: Bool
    let notificationObservations: Bool
    let storekitObservations: Bool
    let locationObservations: Bool
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
         advertiserID: Bool = false,
         notificationObservations: Bool = false,
         storekitObservations: Bool = false,
         locationObservations: Bool = false,
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
        self.advertiserID = advertiserID
        self.notificationObservations = notificationObservations
        self.storekitObservations = storekitObservations
        self.locationObservations = locationObservations
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
        archiver.encode(advertiserID, forKey: "advertiserID")
        archiver.encode(notificationObservations, forKey: "notificationObservations")
        archiver.encode(storekitObservations, forKey: "storekitObservations")
        archiver.encode(locationObservations, forKey: "locationObservations")
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
        guard let customViews = unarchiver.decodeObject(forKey: "customViews") as? [String: Any] else { return nil }
        guard let customEvents = unarchiver.decodeObject(forKey: "customEvents") as? [String: Any] else { return nil }
        self.init(configID: configID,
                  integrationMethod: integrationMethod,
                  reinforcementEnabled: unarchiver.decodeBool(forKey: "reinforcementEnabled"),
                  reportBatchSize: unarchiver.decodeInteger(forKey: "reportBatchSize"),
                  triggerEnabled: unarchiver.decodeBool(forKey: "triggerEnabled"),
                  trackingEnabled: unarchiver.decodeBool(forKey: "trackingEnabled"),
                  trackBatchSize: unarchiver.decodeInteger(forKey: "trackBatchSize"),
                  advertiserID: unarchiver.decodeBool(forKey: "advertiserID"),
                  notificationObservations: unarchiver.decodeBool(forKey: "notificationObservations"),
                  storekitObservations: unarchiver.decodeBool(forKey: "storekitObservations"),
                  locationObservations: unarchiver.decodeBool(forKey: "locationObservations"),
                  applicationState: unarchiver.decodeBool(forKey: "applicationState"),
                  applicationViews: unarchiver.decodeBool(forKey: "applicationViews"),
                  customViews: customViews,
                  customEvents: customEvents,
                  consoleLoggingEnabled: unarchiver.decodeBool(forKey: "consoleLoggingEnabled"))
    }
}
