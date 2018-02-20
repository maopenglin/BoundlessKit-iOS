//
//  DopeActionCollection.swift
//  DopamineKit
//
//  Created by Akash Desai on 2/19/18.
//

import Foundation

internal class DopeActionCollection : SynchronizedArray<DopeAction>, NSCoding {
    
    @objc var sizeForBatch: Int
    @objc fileprivate var timerStartedAt: Int64
    @objc fileprivate var timerExpiresIn: Int64
    
    init(actions: [DopeAction] = [], sizeForBatch: Int = 10, timerStartedAt: Int64 = Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64 = 172800000) {
        self.sizeForBatch = sizeForBatch
        self.timerStartedAt = timerStartedAt
        self.timerExpiresIn = timerExpiresIn
        super.init(actions)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        if let savedActions = aDecoder.decodeObject(forKey: "actions") as? [DopeAction] {
            self.init(actions: savedActions,
                      sizeForBatch: aDecoder.decodeInteger(forKey: #keyPath(DopeActionCollection.sizeForBatch)),
                      timerStartedAt: aDecoder.decodeInt64(forKey: #keyPath(DopeActionCollection.timerStartedAt)),
                      timerExpiresIn: aDecoder.decodeInt64(forKey: #keyPath(DopeActionCollection.timerExpiresIn))
            )
        } else {
            return nil
        }
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.filter({_ in return true}), forKey: "actions")
        aCoder.encode(timerStartedAt, forKey: #keyPath(DopeActionCollection.timerStartedAt))
        aCoder.encode(timerExpiresIn, forKey: #keyPath(DopeActionCollection.timerExpiresIn))
    }
    
    /// Stores an action
    ///
    /// - parameters:
    ///     - action: The action to be stored.
    ///
    func add(_ action: DopeAction) {
        self.append(action)
        
        let num = self.count
        DopeLog.debug("action#\(num) actionID:\(action.actionID) with metadata:\(action.metaData as AnyObject))")
        
        if let ssid = DopeInfo.mySSID {
            action.addMetaData(["ssid": ssid])
        }
        DopeBluetooth.shared.getBluetooth { [weak action] bluetooth in
            if let bluetooth = bluetooth,
                let _ = action {
                action?.addMetaData(["bluetooth": bluetooth])
            }
            DopeLog.debug("action#\(num) actionID:\(String(describing: action?.actionID)) with bluetooth:\(bluetooth as AnyObject))")
        }
        DopeLocation.shared.getLocation { [weak action] location in
            if let location = location,
                let _ = action {
                action?.addMetaData(["location": location])
            }
            DopeLog.debug("action#\(num) actionID:\(String(describing: action?.actionID)) with location:\(location as AnyObject))")
        }

        
    }
    
    
    /// Updates the sync triggers
    ///
    /// - parameters:
    ///     - sizeToSync: The number of tracked actions to trigger a sync. Defaults to previous sizeToSync.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to the current time.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to previous timerExpiresIn.
    ///
    func updateTriggers(timerStartedAt: Int64? = Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64? = nil) {
        if let timerStartedAt = timerStartedAt {
            self.timerStartedAt = timerStartedAt
        }
        if let timerExpiresIn = timerExpiresIn {
            self.timerExpiresIn = timerExpiresIn
        }
    }
    
    /// Check whether the track has been triggered for a sync
    ///
    /// - returns: Whether a sync has been triggered.
    ///
    func isTriggered() -> Bool {
        return timerDidExpire() || batchIsFull()
    }
    
    /// Checks if the sync timer has expired
    ///
    /// - returns: Whether the timer has expired.
    ///
    private func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartedAt + timerExpiresIn)
        //        DopeLog.debugLog("Track timer expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so the timer \(isExpired ? "will" : "won't") trigger a sync...")
        return isExpired
    }
    
    /// Checks if the track is at the size to sync
    ///
    /// - returns: Whether there are enough tracked actions to trigger a sync.
    ///
    private func batchIsFull() -> Bool {
        return count >= sizeForBatch
    }
    
    /// This function returns a snapshot of this instance as a JSON compatible Object
    ///
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject["size"] = NSNumber(value: count)
        jsonObject[#keyPath(DopeActionCollection.timerStartedAt)] = NSNumber(value: timerStartedAt)
        jsonObject[#keyPath(DopeActionCollection.timerExpiresIn)] = NSNumber(value: timerExpiresIn)
        
        return jsonObject
    }
    
}
