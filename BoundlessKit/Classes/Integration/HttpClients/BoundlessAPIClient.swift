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
    
    var properties: BoundlessProperties {
        didSet {
            syncIfNeeded()
        }
    }
    
    let coordinationQueue = DispatchQueue(label: "boundless.kit.api")
    var coordinationWork: DispatchWorkItem?
    
    weak var trackBatch: BoundlessAPISynchronizable?
    weak var reportBatch: BoundlessAPISynchronizable?
    weak var refreshContainer: BoundlessAPISynchronizable?
    var timeDelayAfterTrack: UInt32 = 1
    var timeDelayAfterReport: UInt32 = 5
    var timeDelayAfterRefresh: UInt32 = 3
    
    init(properties: BoundlessProperties, session: URLSessionProtocol = URLSession.shared) {
        self.properties = properties
        super.init(session: session)
    }
    
    func syncIfNeeded() {
        if coordinationWork == nil &&
            (refreshContainer?.needsSync ?? false || reportBatch?.needsSync ?? false || trackBatch?.needsSync ?? false) {
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
            if let trackBatch = self.trackBatch {
                trackBatch.synchronize(with: self) { success in
                    goodProgress = goodProgress && success
                    sema.signal()
                }
                _ = sema.wait(timeout: .now() + 3)
                if goodProgress {
                    sleep(self.timeDelayAfterTrack)
                } else {
                    return
                }
            }
            if let reportBatch = self.reportBatch {
                reportBatch.synchronize(with: self) { success in
                    goodProgress = goodProgress && success
                    sema.signal()
                }
                _ = sema.wait(timeout: .now() + 3)
                if goodProgress {
                    sleep(self.timeDelayAfterReport)
                } else {
                    return
                }
            }
            if let refreshContainer = self.refreshContainer {
                refreshContainer.synchronize(with: self) { success in
                    goodProgress = goodProgress && success
                    sema.signal()
                }
                _ = sema.wait(timeout: .now() + 3)
                if goodProgress {
                    sleep(self.timeDelayAfterRefresh)
                } else {
                    return
                }
            }
            self.coordinationWork = nil
        }
        coordinationWork = work
        coordinationQueue.async(execute: work)
    }
    
}
