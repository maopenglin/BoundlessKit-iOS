//
//  Helper.swift
//  Pods
//
//  Created by Akash Desai on 8/24/17.
//
//

import Foundation

@objc
public class Helper: NSObject {
    
    @objc public static var lastTouchLocationInUIWindow: CGPoint = CGPoint.zero
    
    public static var initialBoot: Date? = {
        let defaultsKey = "DopamineKit.isInitialBoot"
        defer { UserDefaults.standard.set(Date(), forKey: defaultsKey) }
        return UserDefaults.standard.object(forKey: defaultsKey) as? Date
    }()
    
}

open class UserDefaultsSingleton : NSObject, NSCoding {
    override init() { super.init() }
    open func encode(with aCoder: NSCoder) {}
    public required init?(coder aDecoder: NSCoder) {}
    
    static func defaultsKey() -> String {
        return NSStringFromClass(self)
    }
}

public extension UserDefaults {
    
    static var dopamine: UserDefaults {
        return UserDefaults(suiteName: "com.usedopamine.dopaminekit")!
    }
    
    func get<T>(key: String) -> T? {
        if let data = self.value(forKey: key) as? Data,
            let t = NSKeyedUnarchiver.unarchiveObject(with: data) as? T {
            return t
        } else { return nil }
    }
    
    func save(_ value: Any?, forKey key: String) {
        self.setValue((value != nil) ? NSKeyedArchiver.archivedData(withRootObject: value!) as Any? : value, forKey: key)
    }
    
    func get<T:UserDefaultsSingleton>() -> T? {
        return get(key: T.defaultsKey())
    }
    
    func save<T:UserDefaultsSingleton>(_ value: T?) {
        save(value, forKey: T.defaultsKey())
    }
    
}



/// This function takes a hex string and alpha value and returns its UIColor
///
/// - parameters:
///     - hex: A hex string with either format `"#ffffff"` or `"ffffff"` or `"#FFFFFF"`.
///     - alpha: The alpha value to apply to the color, default is 1.0 for opaque
///
/// - returns:
///     The corresponding UIColor for valid hex strings, `UIColor.grayColor()` otherwise.
///
public extension UIColor {
    static func from (hex: String, alpha: CGFloat = 1.0) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.removeFirst()
        }
        
        if cString.characters.count != 6 {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

extension Array {
    func selectRandom() -> Element {
        return self[Int(arc4random_uniform(UInt32(self.count)))]
    }
}
