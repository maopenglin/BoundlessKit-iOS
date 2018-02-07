//
//  StringExtensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

public extension String {
    func image(font:UIFont = .systemFont(ofSize: 24)) -> UIImage {
        let size = self.size(withAttributes: [NSAttributedStringKey.font: font])
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(at: .zero, withAttributes: [NSAttributedStringKey.font: font])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

internal extension String {
    func decode() -> String {
        if let data = self.data(using: .utf8),
            let str = String(data: data, encoding: .nonLossyASCII) {
            return str
        } else {
            return self
        }
    }
    
    var base64DecodedImage: UIImage? {
        if let data = Data(base64Encoded: self, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) {
            return UIImage(data: data)
        }
        return nil
    }
}

internal extension String {
    var isValidIdentity: Bool {
        return !isEmpty && count <= 36 && range(of: "[^a-zA-Z0-9\\-]", options: .regularExpression) == nil
    }
}

@objc
extension NSString {
    static func random(length: Int = 6) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    subscript (index: Int) -> String {
        return self[index...index]
    }
    
}
