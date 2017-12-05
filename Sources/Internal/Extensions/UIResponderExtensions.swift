//
//  UIResponderExtensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

internal extension UIResponder {
    func getParentResponders() -> [String]{
        var responders: [String] = []
        DispatchQueue.main.sync {
            parentResponders(responders: &responders)
        }
        return responders
    }
    
    private func parentResponders(responders: inout [String]) {
        responders.append(NSStringFromClass(type(of:self)))
        if let next = self.next {
            next.parentResponders(responders: &responders)
        }
    }
}
