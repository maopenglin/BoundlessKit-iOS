//
//  MockViewController.swift
//  BoundlessKit_Example
//
//  Created by Akash Desai on 3/7/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import BoundlessKit_Example

@objc
class MockViewController : ViewController {

    @objc dynamic
    func printSomething() {
        print("Something")
    }
    
    @objc dynamic
    func printA(string: String) {
        print(string)
    }
    
    @objc dynamic
    func printA(string: String, and string2: String) {
        print("\(string)+\(string2)")
    }
    
}
