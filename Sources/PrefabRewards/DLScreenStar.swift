//
//  DLScreenStar.swift
//  To Do List
//
//  Created by Akash Desai on 5/29/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func showSolidStar() {
        var singleStarColors = ["blue", "green", "orange", "purple", "red", "yellow"]
        let starImage = UIImage(named: "star-single-\(singleStarColors.removeRandom())")!
        let starView = UIImageView(image: starImage)
        let smallestSide = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        starView.frame = CGRect(x: 0, y: 0, width: smallestSide, height: smallestSide)
        starView.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        starView.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIApplication.shared.keyWindow?.addSubview(starView)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 2.0, options: .curveEaseIn, animations: {
            starView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: .curveEaseIn, animations: {
                starView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                starView.alpha = CGFloat(0)
            }) { _ in
                starView.removeFromSuperview()
            }
        }
    }
}

extension Array {
    mutating func removeRandom() -> Element {
        let randomIndex = Int(arc4random_uniform(UInt32(self.count)))
        return remove(at: randomIndex)
    }
}
