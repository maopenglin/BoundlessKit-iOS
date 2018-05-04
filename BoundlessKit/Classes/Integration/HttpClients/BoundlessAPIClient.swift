//
//  BoundlessAPIClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/13/18.
//

import Foundation

internal enum BoundlessAPIEndpoint {
    case track, report, refresh
    
    var url: URL! { return URL(string: path)! }
    
    var path:String{ switch self{
    case .track: return "https://api.usedopamine.com/v4/app/track/"
    case .report: return "https://api.usedopamine.com/v4/app/report/"
    case .refresh: return "https://api.usedopamine.com/v4/app/refresh/"
        }
    }
}

internal protocol BoundlessAPISynchronizable: class {
    var needsSync: Bool { get }
    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool)->Void)
}

internal class BoundlessAPIClient : HTTPClient {
    
    internal var apiCredentials: [String: Any] {
        get {
            return credentials.apiCredentials(for: version)
        }
    }
    internal var credentials: BoundlessCredentials
    internal var version: BoundlessVersion
    
    internal var database: BKUserDefaults
    internal var trackBatch: BKTrackBatch
    internal var reportBatch: BKReportBatch
    internal var refreshContainer: BKRefreshCartridgeContainer
    
    let coordinationQueue = DispatchQueue(label: "boundless.kit.api")
    var coordinationWork: DispatchWorkItem?
    var timeDelayAfterTrack: UInt32 = 1
    var timeDelayAfterReport: UInt32 = 5
    var timeDelayAfterRefresh: UInt32 = 3
    
    init(credentials: BoundlessCredentials, version: BoundlessVersion, database: BKUserDefaults, session: URLSessionProtocol = URLSession.shared) {
        self.credentials = credentials
        self.version = version
        self.database = database
        self.trackBatch = BKTrackBatch.initWith(database: database, forKey: "trackBatch")
        self.reportBatch = BKReportBatch.initWith(database: database, forKey: "reportBatch")
        self.refreshContainer = BKRefreshCartridgeContainer.initWith(database: database, forKey: "refreshContainer")
        super.init(session: session)
    }
    
    func syncIfNeeded() {
        if coordinationWork == nil &&
            (refreshContainer.needsSync || reportBatch.needsSync || trackBatch.needsSync) {
            synchronize()
        }
    }
    
    func synchronize(successful: @escaping (Bool)->Void = {_ in}) {
        guard coordinationWork == nil else {
            successful(false)
            return
        }
        BKLog.debug("Starting api synchronization...")
        let work = DispatchWorkItem() {
            var goodProgress = true
            defer {
                BKLog.debug("Finished api synchronization.")
                successful(goodProgress)
            }
            
            let sema = DispatchSemaphore(value: 0)
            self.trackBatch.synchronize(with: self) { success in
                goodProgress = goodProgress && success
                sema.signal()
            }
            _ = sema.wait(timeout: .now() + 3)
            if goodProgress {
                sleep(self.timeDelayAfterTrack)
            } else {
                return
            }
            
            self.reportBatch.synchronize(with: self) { success in
                goodProgress = goodProgress && success
                sema.signal()
            }
            _ = sema.wait(timeout: .now() + 3)
            if goodProgress {
                sleep(self.timeDelayAfterReport)
            } else {
                return
            }
            
            self.refreshContainer.synchronize(with: self) { success in
                goodProgress = goodProgress && success
                sema.signal()
            }
            _ = sema.wait(timeout: .now() + 3)
            if goodProgress {
                sleep(self.timeDelayAfterRefresh)
            } else {
                return
            }
            
            self.coordinationWork = nil
        }
        coordinationWork = work
        coordinationQueue.async(execute: work)
    }
    
}
