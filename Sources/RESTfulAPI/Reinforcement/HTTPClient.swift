//
//  HTTPClient.swift
//  DopamineKit
//
//  Created by Akash Desai on 2/21/18.
//

import Foundation

internal class HTTPClient {
    
    private let session: URLSessionProtocol
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    func post(to url: URL, jsonObject: [String: Any], timeout:TimeInterval = 3.0, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions())
        } catch {
            let message = "Error converting object to JSON:(\(jsonObject as AnyObject))"
            DopeLog.debug(message)
            Telemetry.storeException(className: "JSONSerialization", message: message)
            completion(nil, nil, NSError(domain: NSStringFromClass(HTTPClient.self), code: 401, userInfo: [NSLocalizedFailureReasonErrorKey: message, NSLocalizedDescriptionKey: message]))
        }
        
        return session.send(request: request, completionHandler: completion)
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
    func resume()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol { }

