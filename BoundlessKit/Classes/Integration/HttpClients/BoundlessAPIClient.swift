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
    case .track: return "https://reinforce.boundless.ai/v6/app/track/"
    case .report: return "https://reinforce.boundless.ai/v6/app/report/"
    case .refresh: return "https://reinforce.boundless.ai/v6/app/refresh/"
        }
    }
}

internal protocol BoundlessAPISynchronizable: class {
    var needsSync: Bool { get }
    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool)->Void)
}

internal class BoundlessAPIClient : HTTPClient {
    
    internal var credentials: BoundlessCredentials
    internal var version: BoundlessVersion
    
    let coordinationQueue = DispatchQueue(label: "boundless.kit.api")
    var coordinationWork: DispatchWorkItem?
    var timeDelayAfterTrack: UInt32 = 1
    var timeDelayAfterReport: UInt32 = 5
    var timeDelayAfterRefresh: UInt32 = 3
    
    init(credentials: BoundlessCredentials, version: BoundlessVersion, session: URLSessionProtocol = URLSession.shared) {
        self.credentials = credentials
        self.version = version
        super.init(session: session)
    }
    
    func setCustomUserIdentity(_ id: String?) {
        credentials.identity.setSource(customValue: id)
    }
    
    func syncIfNeeded() {
        if coordinationWork == nil &&
            (version.refreshContainer.needsSync || version.reportBatch.needsSync || version.trackBatch.needsSync) {
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
                self.coordinationWork = nil
                successful(goodProgress)
            }
            
            let sema = DispatchSemaphore(value: 0)
            self.version.trackBatch.synchronize(with: self) { success in
                goodProgress = goodProgress && success
                sema.signal()
            }
            _ = sema.wait(timeout: .now() + 3)
            if goodProgress {
                sleep(self.timeDelayAfterTrack)
            } else {
                return
            }
            
            self.version.reportBatch.synchronize(with: self) { success in
                goodProgress = goodProgress && success
                sema.signal()
            }
            _ = sema.wait(timeout: .now() + 3)
            if goodProgress {
                sleep(self.timeDelayAfterReport)
            } else {
                return
            }
            
            self.version.refreshContainer.synchronize(with: self) { success in
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
        coordinationWork = work
        coordinationQueue.async(execute: work)
    }
    
}
