//
//  MockHTTPClient.swift
//  DopamineKit_Tests
//
//  Created by Akash Desai on 2/22/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import DopamineKit

class MockURLSession : URLSessionProtocol, URLSessionDataTaskProtocol {
    func send(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        print("Trying to send to url:\(String(describing: request.url))")
        
        return self
    }
    
    func start() {
        print("DId resume")
    }
    
    
}

//protocol URLSessionProtocol {
//    func send(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
//}
//
//extension URLSession: URLSessionProtocol {
//    func send(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
//        return dataTask(with: request, completionHandler: completionHandler)
//    }
//}
//
//protocol URLSessionDataTaskProtocol {
//    func resume()
//}
//
//extension URLSessionDataTask: URLSessionDataTaskProtocol { }

