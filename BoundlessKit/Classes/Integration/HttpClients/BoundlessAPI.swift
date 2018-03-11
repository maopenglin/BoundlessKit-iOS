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
    
    internal enum CallType {
        case track, report, refresh
        
        var url: URL! { return URL(string: path)! }
        
        var path:String{ switch self{
        case .track: return "https://api.usedopamine.com/v4/app/track/"
        case .report: return "https://api.usedopamine.com/v4/app/report/"
        case .refresh: return "https://api.usedopamine.com/v4/app/refresh/"
            }
        }
    }
    
    let properties: BoundlessProperties
    internal var httpClient = HTTPClient()
    
    init(properties: BoundlessProperties, httpClient: HTTPClient = HTTPClient()) {
        self.properties = properties
        self.httpClient = httpClient
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
        
        httpClient.post(url: CallType.track.url, jsonObject: payload) { response in
            completion(response ?? [:])
        }.start()
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
        
        httpClient.post(url: CallType.report.url, jsonObject: payload) { response in
            completion(response ?? [:])
        }.start()
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
        httpClient.post(url: CallType.refresh.url, jsonObject: payload) { response in
            completion(response ?? [:])
        }.start()
    }
    
}
