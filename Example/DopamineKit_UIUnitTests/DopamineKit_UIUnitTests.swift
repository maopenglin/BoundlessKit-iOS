//
//  DopamineKit_UIUnitTests.swift
//  DopamineKit_UIUnitTests
//
//  Created by Akash Desai on 2/15/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import DopamineKit
//@testable import DopamineKit_Example

class DopamineKit_UIUnitTests: XCTestCase {
    
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
//        XCUIApplication().launch()
         app = XCUIApplication()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testRewards() {
//        app.launch()
//        app.navigationBars["Testing"].buttons["Rewards"].tap()
//        
//        // given
//        class ChangesDelegate : NSObject, DopamineChangesDelegate {
//            var didRewardBlock: (() -> Void)? = nil
//            
//            func didShowReward() {
//                didRewardBlock?()
//            }
//        }
//        
//        let changesDelegate = ChangesDelegate()
//        DopamineChanges.shared.delegate = changesDelegate
//        
//        CodelessAPI.connectionID = "testing"
//        
//        // when
//        var rewardCount = 0
//        changesDelegate.didRewardBlock = {
//            rewardCount += 1
//        }
//        let collectionViewsQuery = app.collectionViews
//        collectionViewsQuery/*@START_MENU_TOKEN@*/.cells.staticTexts["shimmy"]/*[[".cells.staticTexts[\"shimmy\"]",".staticTexts[\"shimmy\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.tap()
//        collectionViewsQuery/*@START_MENU_TOKEN@*/.staticTexts["pulse"]/*[[".cells.staticTexts[\"pulse\"]",".staticTexts[\"pulse\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        collectionViewsQuery/*@START_MENU_TOKEN@*/.staticTexts["vibrate"]/*[[".cells.staticTexts[\"vibrate\"]",".staticTexts[\"vibrate\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        collectionViewsQuery/*@START_MENU_TOKEN@*/.staticTexts["rotate"]/*[[".cells.staticTexts[\"rotate\"]",".staticTexts[\"rotate\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        collectionViewsQuery/*@START_MENU_TOKEN@*/.staticTexts["glow"]/*[[".cells.staticTexts[\"glow\"]",".staticTexts[\"glow\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        collectionViewsQuery/*@START_MENU_TOKEN@*/.staticTexts["sheen"]/*[[".cells.staticTexts[\"sheen\"]",".staticTexts[\"sheen\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        collectionViewsQuery/*@START_MENU_TOKEN@*/.staticTexts["emojisplosion"]/*[[".cells.staticTexts[\"emojisplosion\"]",".staticTexts[\"emojisplosion\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        collectionViewsQuery/*@START_MENU_TOKEN@*/.staticTexts["confetti"]/*[[".cells.staticTexts[\"confetti\"]",".staticTexts[\"confetti\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        
//        
//        // then
//        sleep(5)
////        print("Showed \(rewardCount) rewards")
////        XCTAssert(rewardCount == 8)
//    }
    
}
