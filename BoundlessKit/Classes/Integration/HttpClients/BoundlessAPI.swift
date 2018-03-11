//
//  BoundlessAPI.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation

@objc
internal class BoundlessAPI : NSObject{
    
    let properties: BoundlessProperties
    internal var httpClient = HTTPClient()
    var logCalls = false
    
    init(properties: BoundlessProperties, httpClient: HTTPClient = HTTPClient(), logCalls: Bool = false) {
        self.properties = properties
        self.httpClient = httpClient
        self.logCalls = logCalls
    }
    
    /// Send an array of actions to the `/track` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    public func send(actions: [[String: Any]], completion: @escaping ([String:Any]) -> ()){
        // create dict with credentials
        var payload = properties.apiCredentials
        
        payload["actions"] = actions
        
        send(call: .track, with: payload, completion: completion)
    }

    /// Send an array of actions to the `/report` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    public func send(reinforcements: [[String: Any]], completion: @escaping ([String:Any]) -> ()){
        var payload = properties.apiCredentials
        
        payload["actions"] = reinforcements
        
        send(call: .report, with: payload, completion: completion)
    }
    
    /// Send an actionID to the `/refresh` path to generate a new cartridge of reinforcement decisions
    ///
    /// - parameters:
    ///     - actionID: The actionID that needs reinforcement decisions.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    public func refresh(actionID: String, completion: @escaping ([String:Any]) -> ()){
        var payload = properties.apiCredentials
        payload["actionID"] = actionID
        
        print("Refreshing \(actionID)...")
        send(call: .refresh, with: payload, completion: completion)
    }
    
    
    /// This function sends a request to BoundlessAI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    internal func send(call type: HTTPClient.CallType, with payload: [String:Any], timeout:TimeInterval = 3.0, completion: @escaping ([String: Any]) -> Void) {
        let task = httpClient.post(type: type, jsonObject: payload) { response in
            
            completion(response ?? [:])
            
            if self.logCalls { print("got response:\(response as AnyObject)") }
        }
        
        // send request
        if logCalls { print("with payload: \(payload as AnyObject)") }
        task.start()
    }
    
}
