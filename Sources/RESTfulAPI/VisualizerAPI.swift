//
//  VisualizerAPI.swift
//  Pods
//
//  Created by Akash Desai on 9/9/17.
//
//

import Foundation

public class VisualizerAPI : NSObject {
    
    /// Valid API actions appeneded to the VisualizerAPI URL
    ///
    internal enum CallType{
        case websessions, record, activeEvents
        var pathExtenstion:String{ switch self{
        case .websessions: return "websessions/"
        case .record: return "event/record/"
        case .activeEvents: return "event/active/"
            }
        }
    }
    
    internal static let shared = VisualizerAPI()
    static var webSessionID: String?
    private static let baseURL = "http://127.0.0.1:5000/visualizer/"
    
    private override init() {
        super.init()
    }
    
    public static func promptPairing() {
        var payload = shared.configurationData
        payload["deviceName"] = UIDevice.current.name
        
        shared.send(call: .websessions, with: payload){ response in
            if let webSessionIDs = response["webSessionIDs"] as? [String] {
                presentPairingAlert(webSessionIDs: webSessionIDs)
            }
        }
    }
    
    private static func presentPairingAlert(webSessionIDs: Array<String>) {
        var webSessionIDs = webSessionIDs
        guard let webSessionID = webSessionIDs.popLast() else {
            return
        }
        
        let pairingAlert = UIAlertController(title: "Visualizer Pairing", message: "Pair with \(webSessionID)", preferredStyle: UIAlertControllerStyle.alert)
        
        pairingAlert.addAction( UIAlertAction( title: "Yes", style: .default, handler: { _ in
            VisualizerAPI.webSessionID = webSessionID
        }))
        
        pairingAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
            presentPairingAlert(webSessionIDs: webSessionIDs)
        }))
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindowLevelAlert + 1;
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(pairingAlert, animated: true, completion: nil)

    }
    
    
    /// This function sends a request to the VisualizerAPI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    private func send(call type: CallType, with payload: [String:Any], timeout:TimeInterval = 3.0, completion: @escaping ([String: Any]) -> Void) {
        let baseURL = URL(string: VisualizerAPI.baseURL)!
        guard let url = URL(string: type.pathExtenstion, relativeTo: baseURL) else {
            DopamineKit.debugLog("Could not construct for \(type.pathExtenstion)")
            return
        }
        
        DopamineKit.debugLog("Preparing \(type.pathExtenstion) api call to \(url.absoluteString)...")
        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.timeoutInterval = timeout
            let jsonPayload = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions())
            //            DopamineKit.debugLog("sending raw payload:\(jsonPayload.debugDescription)")   // hex 16 chars
            request.httpBody = jsonPayload
            
            let callStartTime = Int64( 1000*NSDate().timeIntervalSince1970 )
            let task = URLSession.shared.dataTask(with: request, completionHandler: { responseData, responseURL, error in
                var responseDict: [String : Any] = [:]
                defer { completion(responseDict) }
                
                if responseURL == nil {
                    DopamineKit.debugLog("❌ invalid response:\(String(describing: error?.localizedDescription))")
                    responseDict["error"] = error?.localizedDescription
                    return
                }
                
                if let responseData = responseData,
                    responseData.isEmpty {
                    DopamineKit.debugLog("✅\(type.pathExtenstion) call got empty response.")
                    return
                }
                
                do {
                    // turn the response into a json object
                    guard let data = responseData,
                        let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
                        else {
                            let json = responseData.flatMap({ NSString(data: $0, encoding: String.Encoding.utf8.rawValue) }) ?? ""
                            let message = "❌ Error reading \(type.pathExtenstion) response data, not a dictionary: \(json)"
                            DopamineKit.debugLog(message)
                            Telemetry.storeException(className: "JSONSerialization", message: message)
                            return
                    }
                    responseDict = dict
                    DopamineKit.debugLog("✅\(type.pathExtenstion) call got response:\(responseDict.debugDescription)")
                    
                } catch {
                    let message = "❌ Error reading \(type.pathExtenstion) response data: " + String(describing: (responseData != nil) ? String(data: responseData!, encoding: .utf8) : String(describing: responseData.debugDescription))
                    DopamineKit.debugLog(message)
                    return
                }
                
            })
            
            // send request
            DopamineKit.debugLog("Sending \(type.pathExtenstion) api call with payload: \(payload.description)")
            task.resume()
            
        } catch {
            let message = "Error sending \(type.pathExtenstion) api call with payload:(\(payload.description))"
            DopamineKit.debugLog(message)
            Telemetry.storeException(className: "JSONSerialization", message: message)
        }
    }
    
    
    
    
    /// Computes the basic fields for a request call
    ///
    /// Add this to your payload before calling `send()`
    ///
    private lazy var configurationData: [String: Any] = {
        
        var dict: [String: Any] = [ "primaryIdentity" : self.primaryIdentity ]
        
        // create a credentials dict from .plist
        let credentialsFilename = "DopamineProperties"
        var path:String
        guard let credentialsPath = Bundle.main.path(forResource: credentialsFilename, ofType: "plist") else{
            DopamineKit.debugLog("[DopamineKit]: Error - cannot find credentials in (\(credentialsFilename))")
            return dict
        }
        path = credentialsPath
        
        guard let credentialsPlist = NSDictionary(contentsOfFile: path) as? [String: Any] else{
            DopamineKit.debugLog("[DopamineKit]: Error - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        
        guard let appID = credentialsPlist["appID"] as? String else{
            DopamineKit.debugLog("[DopamineKit]: Error no appID - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["appID"] = appID
        
        guard let versionID = credentialsPlist["versionID"] as? String else{
            DopamineKit.debugLog("[DopamineKit]: Error no versionID - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        dict["versionID"] = versionID
        
        if let inProduction = credentialsPlist["inProduction"] as? Bool{
            if(inProduction){
                guard let productionSecret = credentialsPlist["productionSecret"] as? String else{
                    DopamineKit.debugLog("[DopamineKit]: Error no productionSecret - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = productionSecret
            } else{
                guard let developmentSecret = credentialsPlist["developmentSecret"] as? String else{
                    DopamineKit.debugLog("[DopamineKit]: Error no developmentSecret - (\(credentialsFilename)) is in the wrong format")
                    return dict
                }
                dict["secret"] = developmentSecret
            }
        } else{
            DopamineKit.debugLog("[DopamineKit]: Error no inProduction - (\(credentialsFilename)) is in the wrong format")
            return dict
        }
        
        return dict
    }()
    
    /// Computes a primary identity for the user
    ///
    /// This variable computes an identity for the user and saves it to NSUserDefaults for future use.
    ///
    private lazy var primaryIdentity:String = {
        let key = "DopaminePrimaryIdentity"
        let defaults = UserDefaults.standard
        if let identity = defaults.value(forKey: key) as? String {
            DopamineKit.debugLog("primaryIdentity:(\(identity))")
            return identity
        } else {
            let defaultIdentity = UIDevice.current.identifierForVendor!.uuidString
            defaults.setValue(defaultIdentity, forKey: key)
            return defaultIdentity
        }
    }()

}
