//
//  HTTPClient.swift
//  DopamineKit
//
//  Created by Akash Desai on 2/21/18.
//

import Foundation

internal class HTTPClient {
    
    internal static var logAPIResponses = false
    
    internal enum CallType{
        case track, report, refresh, telemetry,
                identify, accept, submit, boot
        
        func url() -> URL! { return URL(string: path)! }
        
        var path:String{ switch self{
        case .track: return "https://api.usedopamine.com/v4/app/track/"
        case .report: return "https://api.usedopamine.com/v4/app/report/"
        case .refresh: return "https://api.usedopamine.com/v4/app/refresh/"
        case .telemetry: return "https://api.usedopamine.com/v4/telemetry/sync/"
            
        case .identify: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/identity/"
        case .boot: return "https://api.usedopamine.com/v5/app/boot"
        case .accept: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/accept/"
        case .submit: return "https://dashboard-api.usedopamine.com/codeless/visualizer/customer/submit/"
            }
        }
    }
    
    private let session: URLSessionProtocol
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    func post(type: CallType, jsonObject: [String: Any], timeout:TimeInterval = 3.0, completion: @escaping ([String: Any]?) -> Void) -> URLSessionDataTaskProtocol {
        
        var request = URLRequest(url:type.url())
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonObject)
        } catch {
            let message = "\(type.path) call got error while converting request to JSON"
            DopeLog.debug(message)
            Telemetry.storeException(className: "JSONSerialization", message: message, dataDescription: String(describing: jsonObject))
        }
        
        let convertResponseToJSON = {(responseData: Data?, responseURL: URLResponse?, error: Error?) -> [String: Any]? in
            guard responseURL != nil else {
                let message = "\(type.path) call got invalid response with error:<\(error?.localizedDescription as AnyObject)>"
                DopeLog.error(message)
                Telemetry.storeException(className: NSStringFromClass(HTTPClient.self), message: message, dataDescription: String(describing: jsonObject))
                return nil
            }
            
            guard let response = responseData else {
                let message = "\(type.path) call got no response data"
                DopeLog.error(message)
                Telemetry.storeException(className: NSStringFromClass(HTTPClient.self), message: message, dataDescription: String(describing: jsonObject))
                return nil
            }
            
            if response.isEmpty {
                DopeLog.confirmed("\(type.path) called and got empty response")
                return nil
            } else if let jsonResponse = try? JSONSerialization.jsonObject(with: response) as? [String: AnyObject] {
                DopeLog.confirmed("\(type.path) call got json response")
                return jsonResponse
            } else {
                let message = "\(type.path) call got invalid response"
                let dataString: String = (responseData.flatMap({ NSString(data: $0, encoding: String.Encoding.utf8.rawValue) }) ?? "") as String
                DopeLog.error("\(message)\n\t<\(dataString)>")
                Telemetry.storeException(className: NSStringFromClass(HTTPClient.self), message: message, dataDescription: "Sent:<\(String(describing: jsonObject)))>Received:<\(dataString)>")
                return nil
            }
        }
        
        return session.send(request: request) { responseData, responseURL, error in
            let response = convertResponseToJSON( responseData, responseURL, error )
            if HTTPClient.logAPIResponses {
                DopeLog.debug("<\(request.url?.absoluteString ?? "url:nil")> with\nrequest data:<\(jsonObject as AnyObject)>\ngot response:<\(response as AnyObject)>")
            }
            completion(response)
        }
    }
}


protocol URLSessionProtocol {
    func send(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

extension URLSession: URLSessionProtocol {
    func send(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler)
    }
}

protocol URLSessionDataTaskProtocol {
    func start()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {
    func start() {
        DopeLog.debug("Sending \(currentRequest?.url?.absoluteString ?? "nil") api call...")
        resume()
    }
}

