////
////  Test_CodelessIntegration.swift
////  DopamineKit_Tests
////
////  Created by Akash Desai on 2/20/18.
////  Copyright © 2018 CocoaPods. All rights reserved.
////
//
//import Foundation
//import XCTest
//@testable import DopamineKit
//@testable import DopamineKit_Example
//
//class TestCodelessIntegration : XCTestCase {
//
//    var window: UIWindow!
//    var controllerUnderTest: ViewController!
//
//    override func setUp() {
//        SwizzleHelper.injectSelector(DopamineURLSessionDataTask.self, #selector(DopamineURLSessionDataTask.swizzled_resume), URLSessionTask.self, #selector(URLSessionTask.resume))
//
//        DopamineVersion.current.update(visualizer: nil)
//        
//        controllerUnderTest = ViewController.instance()
//
//        window = UIWindow(frame: UIScreen.main.bounds)
//        window.rootViewController = controllerUnderTest
//        window.makeKeyAndVisible()
//
//        sleep(10)
//
//    }
//
//
//    override func tearDown() {
//        DopamineKit.syncCoordinator.flush()          // clears the sync state, recorded actions, and cartridges
//
//        super.tearDown()
//    }
//
//    func test() {
//        sleep(10)
//    }
//}
//
//
//class DopamineURLSessionDataTask : NSObject {
//    @objc func swizzled_resume() {
//        print("Swizzled_resume")
//    }
//}

