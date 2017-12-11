//
//  CodelessAPI.swift
//  Pods
//
//  Created by Akash Desai on 9/9/17.
//
//

import Foundation

@objc
public class CodelessAPI : NSObject {
    
    public static var logCalls = true
    
    /// Valid API actions appeneded to the CodelessAPI URL
    ///
    internal enum CallType{
        case identify, accept, submit, boot
        var path:String{ switch self{
        case .identify: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/identity/"
        case .boot: return "https://api.usedopamine.com/v5/app/boot"
        case .accept: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/accept/"
        case .submit: return "https://dashboard-api.usedopamine.com/codeless/visualizer/customer/submit/"
            }
        }
    }
    
    @objc
    public static let shared = CodelessAPI()
    
    private static var connectionID: String? {
        willSet {
            if connectionID != newValue {
                DopeLog.debug("🔍 \(newValue != nil ? "C" : "Disc")onnected to visualizer")
            }
        }
        didSet {
            if connectionID == nil {
                DopamineVersion.current.update(visualizer: nil)
            } else if submitQueue.isSuspended {
                submitQueue.isSuspended = false
            }
        }
    }
    
    private override init() {
        super.init()
    }
    
    @objc
    public static func boot() {
        var payload = DopamineProperties.current.apiCredentials
        payload["inProduction"] = DopamineProperties.current.inProduction
        payload["currentVersion"] = DopamineVersion.current.versionID ?? "nil"
        payload["currentConfig"] = DopamineConfiguration.current.configID ?? "nil"
        payload["initialBoot"] = (UserDefaults.initialBootDate == nil)
        shared.send(call: .boot, with: payload){ response in
            if let status = response["status"] as? Int {
                if status == 205 {
                    if let configDict = response["config"] as? [String: Any],
                        let config = DopamineConfiguration.convert(from: configDict) {
                        DopamineProperties.current.configuration = config
                    }
                    if let versionDict = response["version"] as? [String: Any],
                        let version = DopamineVersion.convert(from: versionDict) {
                        DopamineProperties.current.version = version
                    }
                }
            }
            
            promptPairing()
        }
    }
    
    @objc
    private static func promptPairing() {
        guard !DopamineProperties.current.inProduction else {
            return
        }
        
        var payload = DopamineProperties.current.apiCredentials
        payload["deviceName"] = UIDevice.current.name
        
        shared.send(call: .identify, with: payload){ response in
            if let status = response["status"] as? Int {
                switch status {
                case 202:
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                        promptPairing()
                    }
                    break
                    
                case 200:
                    if let adminName = response["adminName"] as? String,
                        let connectionID = response["connectionUUID"] as? String {
                        
                        let pairingAlert = UIAlertController(title: "Visualizer Pairing", message: "Accept pairing request from \(adminName)?", preferredStyle: UIAlertControllerStyle.alert)
                        
                        pairingAlert.addAction( UIAlertAction( title: "Yes", style: .default, handler: { _ in
                            var payload = DopamineProperties.current.apiCredentials
                            payload["deviceName"] = UIDevice.current.name
                            payload["connectionUUID"] = connectionID
                            shared.send(call: .accept, with: payload) {response in
                                if response["status"] as? Int == 200 {
                                    CodelessAPI.connectionID = connectionID
                                    
                                    for event in CustomCodelessEvent.appEvents {
                                        submit { payload in
                                            event.modify(payload: &payload)
                                        }
                                    }
                                }
                            }
                        }))
                        
                        pairingAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                            
                        }))
                        
                        UIWindow.presentTopLevelAlert(alertController: pairingAlert)
                    }
                    
                case 208:
                    CodelessAPI.connectionID = response["connectionUUID"] as? String
                    
                case 204:
                    CodelessAPI.connectionID = nil
                    
                case 500:
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    @objc
    public static func recordEvent(touch: UITouch) {
        DispatchQueue.global().async {
            if let view = touch.view,
                touch.phase == .ended {
                
                touch.attemptReinforcement()
                
                submit { payload in
                    let senderClassname = NSStringFromClass(type(of: touch))
                    let targetName = view.getParentResponders().joined(separator: ",")
                    let selectorName = "ended"
                    
                    payload["sender"] = senderClassname
                    payload["target"] = targetName
                    payload["selector"] = selectorName
                    payload["actionID"] = [senderClassname, targetName, selectorName].joined(separator: "-")
                    payload["senderImage"] = ""
                    payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
                    payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
                }
            }
        }
    }
    
    @objc
    public static func recordAction(application: UIApplication, senderInstance: AnyObject, targetInstance: AnyObject, selectorObj: Selector) {
        DispatchQueue.global().async {
            let senderClassname = NSStringFromClass(type(of: senderInstance))
            let targetClassname = NSStringFromClass(type(of: targetInstance))
            let selectorName = NSStringFromSelector(selectorObj)
            
            application.attemptReinforcement(senderInstance: senderInstance, targetInstance: targetInstance, selectorObj: selectorObj)
            
            submit { payload in
                payload["sender"] = senderClassname
                payload["target"] = targetClassname
                payload["selector"] = selectorName
                payload["actionID"] = [senderClassname, targetClassname, selectorName].joined(separator: "-")
                DispatchQueue.main.sync {
                    if let view = senderInstance as? UIView,
                        let imageString = view.snapshotImage()?.base64EncodedPNGString() {
                        payload["senderImage"] = imageString
                    } else if let barItem = senderInstance as? UIBarItem,
                        let image = barItem.image,
                        let imageString = image.base64EncodedPNGString() {
                        payload["senderImage"] = imageString
                    } else if senderInstance.responds(to: NSSelectorFromString("view")),
                        let sv = senderInstance.value(forKey: "view") as? UIView,
                        let imageString = sv.snapshotImage()?.base64EncodedPNGString() {
                        payload["senderImage"] = imageString
                    } else {
                        NSLog("Cannot create image, please message team@usedopamine.com to add support for visualizer snapshots of class type:<\(type(of: senderInstance))>!")
                        payload["senderImage"] = ""
                    }
                }
            }
        }
    }
    
    @objc
    public static func recordAppEvent(name: String) {
        DispatchQueue.global().async {
            let appEvent = CustomCodelessEvent(target: "AppEvent", action: name)
            appEvent.attemptReinforcement()
        }
    }
    
    
    fileprivate static var submitQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        return queue
    }()
    fileprivate static func submit(payloadModifier: (inout [String: Any]) -> Void) {
        if connectionID != nil {
            var payload = DopamineProperties.current.apiCredentials
            payloadModifier(&payload)
            
            submitQueue.addOperation {
                if let connectionID = self.connectionID {
                    payload["connectionUUID"] = connectionID
                    
                    submitQueue.isSuspended = true
                    shared.send(call: .submit, with: payload){ response in
                        defer { submitQueue.isSuspended = false }
                        
                        if response["status"] as? Int != 200 {
                            CodelessAPI.connectionID = nil
                        } else if let visualizerMappings = response["mappings"] as? [String:Any] {
                            DopamineVersion.current.update(visualizer: visualizerMappings)
                        } else {
                            DopeLog.debug("No visualizer mappings found")
                        }
                    }
                }
            }
        }
    }
    
    /// This function sends a request to the CodelessAPI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    private func send(call type: CallType, with payload: [String:Any], timeout:TimeInterval = 3.0, completion: @escaping ([String: Any]) -> Void) {
        guard let url = URL(string: type.path) else {
            DopeLog.debug("Invalid url <\(type.path)>")
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
            DopeLog.debug(message)
            Telemetry.storeException(className: "JSONSerialization", message: message)
        }
        
        let callStartTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let task = URLSession.shared.dataTask(with: request, completionHandler: { responseData, responseURL, error in
            var responseDict: [String : Any] = [:]
            defer { completion(responseDict) }
            
            if responseURL == nil {
                DopeLog.debug("❌ invalid response:\(String(describing: error?.localizedDescription))")
                responseDict["error"] = error?.localizedDescription
                return
            }
            
            if let responseData = responseData,
                responseData.isEmpty {
                DopeLog.debug("✅\(type.path) call got empty response.")
                return
            }
            
            do {
                // turn the response into a json object
                guard let data = responseData,
                    let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    else {
                        let json = responseData.flatMap({ NSString(data: $0, encoding: String.Encoding.utf8.rawValue) }) ?? ""
                        let message = "❌ Error reading \(type.path) response data, not a dictionary: \(json)"
                        DopeLog.debug(message)
                        Telemetry.storeException(className: "JSONSerialization", message: message)
                        return
                }
                responseDict = dict
            } catch {
                DopeLog.debug("❌ Error reading \(type.path) response data: \(String(describing: (responseData != nil) ? String(data: responseData!, encoding: .utf8) : String(describing: responseData.debugDescription)))")
                return
            }
            
            if CodelessAPI.logCalls { DopeLog.debug("✅\(type.path) call got response:\(responseDict as AnyObject)") }
        })
        
        // send request
        if CodelessAPI.logCalls { DopeLog.debug("Sending \(type.path) api call with payload: \(payload as AnyObject)") }
        task.resume()
        
    }
}


