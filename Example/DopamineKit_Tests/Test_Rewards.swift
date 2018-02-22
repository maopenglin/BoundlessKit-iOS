//
//  Test_Rewards.swift
//  DopamineKit_Tests
//
//  Created by Akash Desai on 2/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import DopamineKit
@testable import DopamineKit_Example

class TestRewards: XCTestCase {
    
    var window: UIWindow!
    var controllerUnderTest: ViewController!
    
    override func setUp() {
        super.setUp()
        
        DopamineVersion.current.update(visualizer: nil)
        
        controllerUnderTest = ViewController.instance()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controllerUnderTest
        window.makeKeyAndVisible()
    }
    
    override func tearDown() {
        DopamineKit.syncCoordinator.flush()          // clears the sync state, recorded actions, and cartridges
        
        super.tearDown()
    }
    
//    func testAReward() {
//        sleep(4)
//        
//        // given
//        let rewardMapping = controllerUnderTest.didReceiveSomeUIEventReward
//        let someActionID = rewardMapping.keys.first!
//        class DKDelegate : DopamineKitDelegate {
//            func willTryReinforce(actionID: String, with decision: String) {
//                print("In testdelegate")
//            }
//        }
//        let rewardDelegate = DKDelegate()
////        DopamineChanges.shared.delegate = rewardDelegate
//        
//        // when
//        DopamineVersion.current.update(visualizer: rewardMapping)
//        let promise = expectation(description: "Reinforcing mapped action")
////        rewardDelegate.reinforcingBlock = { (actionID, reinforcementDecision) in
////            print("Actionid for promise:\(actionID)")
////            if someActionID == actionID {
////                promise.fulfill()
////            }
////        }
//        sleep(1)
//        controllerUnderTest.didReceiveSomeUIEvent()
//        sleep(2)
//        // then
//        waitForExpectations(timeout: 3, handler: {error in
//            XCTAssertNil(error, "DopamineKitTest error: dopamine delegate timed out")
//        })
//    }
    
    func testBoot() {
        let asyncExpectation = expectation(description: "Sent boot call")
        
        CodelessAPI.boot {
            asyncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
        })
    }
    
    
    func testRewardShimmy() {
        // given
        let promise1 = expectation(description: "Shimmy reward")
        
        // when
        controllerUnderTest.view.showShimmy {
            promise1.fulfill()
        }
        
        // then
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRewardPulse() {
        // given
        let promise1 = expectation(description: "Pulse reward")
        
        // when
        controllerUnderTest.view.showPulse {
            promise1.fulfill()
        }
        
        // then
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRewardVibrate() {
        // given
        let promise1 = expectation(description: "Vibrate reward")
        
        // when
        controllerUnderTest.view.showVibrate {
            promise1.fulfill()
        }
        
        // then
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRewardRotate() {
        // given
        let promise1 = expectation(description: "Rotate reward")
        
        // when
        controllerUnderTest.view.rotate360Degrees {
            promise1.fulfill()
        }
        
        // then
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRewardGlow() {
        // given
        let promise1 = expectation(description: "Glow reward")
        
        // when
        controllerUnderTest.view.showGlow {
            promise1.fulfill()
        }
        
        // then
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRewardSheen() {
        // given
        let promise1 = expectation(description: "Sheen reward")
        
        // when
        controllerUnderTest.view.showSheen {
            promise1.fulfill()
        }
        
        // then
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRewardConfetti() {
        // given
        let promise1 = expectation(description: "Confetti reward")
        
        // when
        controllerUnderTest.view.showConfetti {
            promise1.fulfill()
        }
        
        // then
        waitForExpectations(timeout: 7, handler: nil)
    }
    
    func testRewardEmojiSplosion() {
        // given
        let promise1 = expectation(description: "EmojiSplosion reward")
        
        // when
        controllerUnderTest.view.showEmojiSplosion(at: controllerUnderTest.view.center) {
            promise1.fulfill()
        }
        
        // then
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}
