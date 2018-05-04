//
//  MockHTTPClient.swift
//  BoundlessKit_Example
//
//  Created by Akash Desai on 3/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import BoundlessKit

extension BoundlessProperties {
    static var fromTestFile: BoundlessProperties? {
        if let propertiesFile = Bundle(for: MockBoundlessKit.self).path(forResource: "BoundlessTestProperties", ofType: "plist"),
            let propertiesDictionary = NSDictionary(contentsOfFile: propertiesFile) as? [String: Any],
            let credentials = BoundlessCredentials.convert(from: propertiesDictionary) {
            return BoundlessProperties(credentials: credentials,
                                       version: BoundlessVersion.convert(from: propertiesDictionary) ?? BoundlessVersion())
        } else {
            return nil
        }
    }
}

class MockBoundlessAPIClient : BoundlessAPIClient {
    init() {
        let properties = BoundlessProperties.fromTestFile!
        super.init(credentials: properties.credentials, version: properties.version, database: MockBKuserDefaults(), session: MockURLSession())
        logRequests = true
        logResponses = true
    }
}

class MockCodelessAPIClient : CodelessAPIClient {
    init() {
        let properties = BoundlessProperties.fromTestFile!
        super.init(credentials: properties.credentials, version: properties.version, database: MockBKuserDefaults(), session: MockURLSession())
        self.refreshContainer = MockBKRefreshCartridgeContainer([:])
        logRequests = true
        logResponses = true
    }
}


class MockURLSession: URLSessionProtocol {
    
    //MARK: Mock Responses
    internal var mockResponse: [URL: [String: Any]] = [:]
    
    //MARK: Protocol Method
    func send(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        print("Mock http request to url:\(String(describing: request.url!))")
        
        return MockURLSessionDataTask(
            request: request,
            responseData: try! JSONSerialization.data(withJSONObject: mockResponse[request.url!] ?? ["status": 200]),
            completion: completionHandler
        )
    }
}

class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    let urlRequest: URLRequest
    let mockResponseData: Data
    let taskFinishHandler: (Data?, URLResponse?, Error?) -> Void
    
    init(request: URLRequest, responseData: Data, completion: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        urlRequest = request
        mockResponseData = responseData
        taskFinishHandler = completion
    }
    
    func start() {
        print("Did start url session data task to:<\(String(describing: urlRequest.url))> with \nrequest data:\(try! JSONSerialization.jsonObject(with: urlRequest.httpBody!)) \nmock response:<\(try! JSONSerialization.jsonObject(with: mockResponseData))> ")
        DispatchQueue.global().async {
            self.taskFinishHandler(self.mockResponseData, URLResponse(), nil)
        }
    }
}
