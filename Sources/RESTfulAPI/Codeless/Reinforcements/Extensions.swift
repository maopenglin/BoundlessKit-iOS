//
//  Extensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/27/17.
//

import Foundation


internal extension DopamineKit {
    class var frameworkBundle: Bundle? {
        if let bundleURL = Bundle(for: DopamineKit.classForCoder()).url(forResource: "DopamineKit", withExtension: "bundle") {
            return Bundle(url: bundleURL)
        } else {
            DopeLog.debug("The DopamineKit framework bundle cannot be found")
            return nil
        }
    }
}

internal extension UIWindow {
    class var topWindow: UIWindow? {
        get {
            if let window = UIApplication.shared.keyWindow {
                return window
            }
            for window in UIApplication.shared.windows.reversed() {
                if window.windowLevel == UIWindowLevelNormal && !window.isHidden && window.frame != CGRect.zero { return window }
            }
            return nil
        }
    }
}

internal extension CGImage {
    func blurImage(radius: Int) -> CGImage {
        guard radius != 0 else {
            return self
        }
        let imageToBlur = CIImage(cgImage: self)
        let blurfilter = CIFilter(name: "CIGaussianBlur")!
        blurfilter.setValue(radius, forKey: kCIInputRadiusKey)
        blurfilter.setValue(imageToBlur, forKey: kCIInputImageKey)
        let resultImage = blurfilter.value(forKey: kCIOutputImageKey) as! CIImage
        
        let context = CIContext(options: nil)
        return context.createCGImage(resultImage, from: resultImage.extent)!
    }
}

public extension String {
    func image(font:UIFont = .systemFont(ofSize: 24)) -> UIImage {
        let size = (self as NSString).size(withAttributes: [NSAttributedStringKey.font: font])
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        (self as NSString).draw(at: .zero, withAttributes: [NSAttributedStringKey.font: font])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

internal extension String {
//    var data:          Data  { return Data(utf8) }
//    var base64Encoded: Data  { return data.base64EncodedData() }
//    var base64Decoded: Data? { return Data(base64Encoded: self, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) }
//    var pngDecoded: UIImage? { print("test1"); return UIImage(data: base64Decoded!) }
    
    func decodeAsPNG() -> UIImage? {
        if let data = Data(base64Encoded: self, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) {
            return UIImage(data: data)
        } else {
            return nil
        }
    }
}

//internal extension Data {
//    var string: String? { return String(data: self, encoding: .utf8) }
//}

internal extension CGFloat {
    func degreesToRadians() -> CGFloat {
        return self / 180 * .pi
    }
    
    init(degrees: CGFloat) {
        self = degrees.degreesToRadians()
    }
}

