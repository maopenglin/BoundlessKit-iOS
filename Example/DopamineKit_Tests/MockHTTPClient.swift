//
//  MockHTTPClient.swift
//  DopamineKit_Tests
//
//  Created by Akash Desai on 2/22/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import DopamineKit

class MockURLSession : URLSessionProtocol {
    
    var lastURL: URL?
    var mockResponse: [String: Any] = [:]
    
    func send(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        DopeLog.debug("Trying to send to url:\(String(describing: request.url))")
        
        lastURL = request.url
        
        return MockURLSessionDataTask(
            request: request,
            responseData: try! JSONSerialization.data(withJSONObject: mockResponse),
            completion: completionHandler
        )
    }
    
}

class MockURLSessionDataTask : URLSessionDataTaskProtocol {
    
    let urlRequest: URLRequest
    let mockResponseData: Data
    let taskFinishHandler: (Data?, URLResponse?, Error?) -> Void
    
    init(request: URLRequest, responseData: Data, completion: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        urlRequest = request
        mockResponseData = responseData
        taskFinishHandler = completion
    }
    
    func start() {
//        DopeLog.debug("Did start url session data task to:<\(String(describing: urlRequest.url))> with \nrequest data:\(try! JSONSerialization.jsonObject(with: urlRequest.httpBody!)) \nmock response:<\(try! JSONSerialization.jsonObject(with: mockResponseData))> ")
        
        taskFinishHandler(mockResponseData, URLResponse(), nil)
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

