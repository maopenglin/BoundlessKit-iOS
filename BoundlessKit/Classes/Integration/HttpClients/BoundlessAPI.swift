//
//  BoundlessAPI.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation

@objc
public class BoundlessAPI : NSObject{
    
    public static var logCalls = false
    
    /// Valid API actions appeneded to the BoundlessAI URL
    ///
    internal enum CallType{
        case track, report, refresh
        var path:String{ switch self{
        case .track: return "https://api.usedopamine.com/v4/app/track/"
        case .report: return "https://api.usedopamine.com/v4/app/report/"
        case .refresh: return "https://api.usedopamine.com/v4/app/refresh/"
            }
        }
    }
    
    internal static let shared: BoundlessAPI = BoundlessAPI()
    
    private override init() {
        super.init()
    }
    
    /// Send an array of actions to the `/track` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    internal static func send(actions: [BoundlessAction], completion: @escaping ([String:Any]) -> ()){
        // create dict with credentials
//        var payload = BoundlessProperties.current.apiCredentials
        var payload = [String:Any]()
        
        // get JSON formatted actions
        var trackedActionsJSONArray = Array<Any>()
        for action in actions{
            trackedActionsJSONArray.append(action.toJSONType())
        }
        
        payload["actions"] = trackedActionsJSONArray
        
        shared.send(call: .track, with: payload, completion: completion)
    }

    /// Send an array of actions to the `/report` path
    ///
    /// - parameters:
    ///     - actions: An array of actions to send.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    internal static func send(reinforcments: [BoundlessReinforcement], completion: @escaping ([String:Any]) -> ()){
//        var payload = BoundlessProperties.current.apiCredentials
        var payload = [String:Any]()
        
        var reinforcmentsArray = Array<Any>()
        for reinforcment in reinforcments {
            reinforcmentsArray.append(reinforcment.toJSONType())
        }
        
        payload["actions"] = reinforcmentsArray
        
        shared.send(call: .report, with: payload, completion: completion)
    }
    
    /// Send an actionID to the `/refresh` path to generate a new cartridge of reinforcement decisions
    ///
    /// - parameters:
    ///     - actionID: The actionID that needs reinforcement decisions.
    ///     - completion: A closure to handle the JSON formatted response.
    ///
    internal static func refresh(actionID: String, completion: @escaping ([String:Any]) -> ()){
//        var payload = BoundlessProperties.current.apiCredentials
        var payload = [String:Any]()
        payload["actionID"] = actionID
        
        print("Refreshing \(actionID)...")
        shared.send(call: .refresh, with: payload, completion: completion)
    }
    
    private lazy var session = URLSession.shared
    
    /// This function sends a request to BoundlessAI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    private func send(call type: CallType, with payload: [String:Any], timeout:TimeInterval = 3.0, completion: @escaping ([String: Any]) -> Void) {
//        if true {
//            return
//        }
        guard let url = URL(string: type.path) else {
            print("Invalid url <\(type.path)>")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions())
        } catch {
            let message = "Error sending \(type.path) api call with payload:(\(payload as AnyObject))"
            print(message)
        }
        let callStartTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let task = session.dataTask(with: request, completionHandler: { responseData, responseURL, error in
            var responseDict: [String : Any] = [:]
            defer { completion(responseDict) }
            
            if responseURL == nil {
                print("❌ invalid response:\(String(describing: error?.localizedDescription))")
                responseDict["error"] = error?.localizedDescription
                return
            }
            
            do {
                guard let data = responseData,
                    let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
                    else {
                        let json = responseData.flatMap({ NSString(data: $0, encoding: String.Encoding.utf8.rawValue) }) ?? ""
                        let message = "❌ Error reading \(type.path) response data, not a dictionary: \(json)"
                        print(message)
                        return
                }
                responseDict = dict
            } catch {
                let message = "❌ Error reading \(type.path) response data: \(responseData.debugDescription)"
                print(message)
                return
            }
            
            print("✅\(type.path) call")
            if BoundlessAPI.logCalls { print("got response:\(responseDict.debugDescription)") }
        })
        
        // send request
        print("Sending \(type.path) api call")
        if BoundlessAPI.logCalls { print("with payload: \(payload as AnyObject)") }
        task.resume()
        
    }
    
}
