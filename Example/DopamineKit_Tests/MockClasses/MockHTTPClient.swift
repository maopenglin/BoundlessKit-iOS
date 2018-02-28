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
    
    //MARK: Protocol Method
    func send(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        DopeLog.debug("Mock http request to url:\(String(describing: request.url!))")
        
        return MockURLSessionDataTask(
            request: request,
            responseData: try! JSONSerialization.data(withJSONObject: mockResponse[request.url!] ?? ["status": 200]),
            completion: completionHandler
        )
    }
    
    //MARK: Mock Responses
    fileprivate var mockResponse: [URL: [String: Any]] = [:]
    
    func setMockResponse(for callType: HTTPClient.CallType, _ response: [String: Any]) {
        mockResponse[callType.url()] = response
    }
    
    func setCodelessPairingReconnected() {
        setMockResponse(for: .identify, [
            "status": 208,
            "connectionUUID": "unittest"
            ]
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
        DispatchQueue.global().async {
            self.taskFinishHandler(self.mockResponseData, URLResponse(), nil)
        }
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

