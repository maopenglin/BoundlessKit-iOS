//
//  CodelessDashboardSession.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/14/18.
//

import Foundation

internal class CodelessDashboardSession : NSObject, NSCoding {
    
    var adminName: String
    var connectionUUID: String
    var visualizerMappings: [String: [String: Any]]
    
    fileprivate lazy var submitQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        return queue
    }()
    
    init(adminName: String, connectionUUID: String, visualizerMappings: [String: [String: Any]]) {
        self.adminName = adminName
        self.connectionUUID = connectionUUID
        self.visualizerMappings = visualizerMappings
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let adminName = aDecoder.decodeObject(forKey: "adminName") as? String,
            let connectionUUID = aDecoder.decodeObject(forKey: "connectionUUID") as? String,
            let visualizerMappings = aDecoder.decodeObject(forKey: "visualizerMappings") as? [String: [String: Any]] else {
                return nil
        }
        self.init(adminName: adminName, connectionUUID: connectionUUID, visualizerMappings: visualizerMappings)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(adminName, forKey: "adminName")
        aCoder.encode(connectionUUID, forKey: "connectionUUID")
        aCoder.encode(visualizerMappings, forKey: "visualizerMappings")
    }
    
    func submitToDashboard(codelessReinforcer: CodelessReinforcer, senderInstance: AnyObject?, with apiClient: CodelessAPIClient) {
        submitQueue.addOperation {
            
        }
    }
}
