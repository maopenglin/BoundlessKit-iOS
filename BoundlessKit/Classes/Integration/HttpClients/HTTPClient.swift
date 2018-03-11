//
//  HTTPClient.swift
//  DopamineKit
//
//  Created by Akash Desai on 2/21/18.
//

import Foundation

internal class HTTPClient {
    
    internal static var logAPIResponses = true
    
    internal enum CallType{
        case track, report, refresh
        
        func url() -> URL! { return URL(string: path)! }
        
        var path:String{ switch self{
        case .track: return "https://api.usedopamine.com/v4/app/track/"
        case .report: return "https://api.usedopamine.com/v4/app/report/"
        case .refresh: return "https://api.usedopamine.com/v4/app/refresh/"
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
            print(message)
        }
        
        let convertResponseToJSON = {(responseData: Data?, responseURL: URLResponse?, error: Error?) -> [String: Any]? in
            guard responseURL != nil else {
                let message = "\(type.path) call got invalid response with error:<\(error?.localizedDescription as AnyObject)>"
                print(message)
                return nil
            }
            
            guard let response = responseData else {
                let message = "\(type.path) call got no response data"
                print(message)
                return nil
            }
            
            if response.isEmpty {
                print("\(type.path) called and got empty response")
                return nil
            } else if let jsonResponse = try? JSONSerialization.jsonObject(with: response) as? [String: AnyObject] {
                print("\(type.path) call got json response")
                return jsonResponse
            } else {
                let message = "\(type.path) call got invalid response"
                let dataString: String = (responseData.flatMap({ NSString(data: $0, encoding: String.Encoding.utf8.rawValue) }) ?? "") as String
                print("\(message)\n\t<\(dataString)>")
                return nil
            }
        }
        
        return session.send(request: request) { responseData, responseURL, error in
            let response = convertResponseToJSON( responseData, responseURL, error )
            if HTTPClient.logAPIResponses {
                print("<\(request.url?.absoluteString ?? "url:nil")> with\nrequest data:<\(jsonObject as AnyObject)>\ngot response:<\(response as AnyObject)>")
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
        print("Sending \(currentRequest?.url?.absoluteString ?? "nil") api call...")
        resume()
    }
}

