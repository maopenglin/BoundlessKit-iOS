//
//  HTTPClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 2/21/18.
//

import Foundation

internal class HTTPClient : NSObject {
    
    internal var logRequests = true
    internal var logResponses = true
    
    private let session: URLSessionProtocol
    
    public init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    func post(url: URL, jsonObject: [String: Any], timeout:TimeInterval = 3.0, completion: @escaping ([String: Any]?) -> Void) -> URLSessionDataTaskProtocol {
        
        if logRequests {
            BKLog.print("Sending request to <\(url.absoluteString)> with paylaod:\n<\(jsonObject)>...")
        }
        
        var request = URLRequest(url:url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonObject)
        } catch {
            let message = "\(url.absoluteString) call got error while converting request to JSON"
            BKLog.print(error: message)
        }
        
        return session.send(request: request) { responseData, responseURL, error in
            let response = self.convertResponseToJSON(url, responseData, responseURL, error)
            if self.logResponses {
//                BKLog.print("Received response from <\(request.url?.absoluteString ?? "url:nil")> with payload:\n<\(response as AnyObject)>")
                BKLog.print("Received response from <\(request.url?.absoluteString ?? "url:nil")> with payload:\n<\(String(describing: String(data: responseData!, encoding: String.Encoding.utf8)))>")
            }
            completion(response)
        }
    }
    
    fileprivate func convertResponseToJSON(_ url: URL, _ responseData: Data?, _ responseURL: URLResponse?, _ error: Error?)  -> [String: Any]? {
        guard responseURL != nil else {
            let message = "\(url.absoluteString) call got invalid response with error:<\(error?.localizedDescription as AnyObject)>"
            BKLog.print(error: message)
            return nil
        }
        
        guard let response = responseData else {
            let message = "\(url.absoluteString) call got no response data"
            BKLog.debug(message)
            return nil
        }
        
        if response.isEmpty {
            BKLog.debug("\(url.absoluteString) called and got empty response")
            return nil
        } else if let jsonResponse = try? JSONSerialization.jsonObject(with: response) as? [String: AnyObject] {
            BKLog.debug("\(url.absoluteString) call got json response")
            return jsonResponse
        } else {
            let message = "\(url.absoluteString) call got invalid response"
            let dataString: String = (responseData.flatMap({ NSString(data: $0, encoding: String.Encoding.utf8.rawValue) }) ?? "") as String
            BKLog.print(error: "\(message)\n\t<\(dataString)>")
            return nil
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
        resume()
    }
}
