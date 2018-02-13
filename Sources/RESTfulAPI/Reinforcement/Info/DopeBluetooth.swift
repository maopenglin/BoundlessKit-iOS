//
//  DopeBluetooth.swift
//  DopamineKit
//
//  Created by Akash Desai on 5/12/17.
//  Copyright © 2017 UseDopamine. All rights reserved.
//

import Foundation
import CoreBluetooth

public class DopeBluetooth : NSObject {
    
    public static let shared = DopeBluetooth()
    
    fileprivate override init() {
        super.init()
//        BluetoothManager.probe = BluetoothManager(delegate: self, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: 0])
    }
    
    public func getBluetooth(callback: @escaping([[String: Any]]?) -> Void) {
//        guard canGetBluetooth else {
//            callback(nil)
//            return
//        }
        BluetoothManager.queue.addOperation {
            if !BluetoothManager.canScanConfirmed {
                BluetoothManager.probe = BluetoothManager(delegate: self, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: 0])
                print("Created probe bluetooth")
                sleep(2)
                print("Done waiting for probe bluetooth")
                BluetoothManager.canScanConfirmed = true
            }
            BluetoothManager.scan(delegate: self, completion: callback)
        }
    }
    
}

extension DopeBluetooth : CBPeripheralDelegate, CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        BluetoothManager.canScan = (central.state == .poweredOn)
        BluetoothManager.canScanConfirmed = true
        
        print("Manager did update bluetooth state on?:\(BluetoothManager.canScan)")
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        BluetoothManager.addTooth(peripheral: peripheral, rssi: RSSI)
    }
    
}


fileprivate class BluetoothManager : CBCentralManager {
    
    struct BluetoothInfo {
        var utc: Date
        var uuid: String
        var name: String
        var rssi: NSNumber
        
        var info: [String: Any] {
            return ["utc": Int64(1000*utc.timeIntervalSince1970),
                    "uuid": uuid,
                    "name": name,
                    "rssi": rssi
            ]
        }
    }
    
    var teeth = [String: BluetoothInfo]()
    var finishHandlers = [(([[String: Any]]?) -> Void)?]()
    
    func finish() {
        if isScanning { stopScan() }
        var devices = [[String: Any]]()
        for (_, device) in teeth {
            devices.append(device.info)
        }
        
        for finishHandler in finishHandlers {
            finishHandler?(devices)
        }
    }
    
    fileprivate static var managers = [Date: BluetoothManager]()
    fileprivate static var probe: BluetoothManager?
    fileprivate static var queue = OperationQueue()
    fileprivate static var canScan: Bool = false
    fileprivate static var canScanConfirmed: Bool = false {
        didSet {
            if canScanConfirmed {
                if !canScan {
                    BluetoothManager.queue.addOperation {
                        print("Confirmed bluetoothmanager can't scan")
                        for (key, manager) in managers {
                            manager.finish()
                            managers.removeValue(forKey: key)
                            print("Removed bluetoothmanager for key:\(key)")
                        }
                    }
                }
            }
        }
    }
    fileprivate static let scanDuration = TimeInterval(5)
    
    static func scan(delegate: CBCentralManagerDelegate, completion: @escaping (([[String: Any]]?) -> Void)) {
        queue.addOperation {
            if !canScanConfirmed || !canScan {
                completion(nil)
                print("Can't scan bluetooth")
                return
            }
            
            let scanStartDate = Date()
            guard managers[scanStartDate] == nil else {
                managers[scanStartDate]?.finishHandlers.append(completion)
                return
            }
            
            if let manager = managers[scanStartDate] {
                manager.finishHandlers.append(completion)
                return
            }
            let manager = BluetoothManager(delegate: nil, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: 0])
            manager.delegate = delegate
            manager.scanForPeripherals(withServices: nil, options: nil)
            managers[scanStartDate] = manager
            
            print("Created bluetoothmanager for \(scanStartDate as AnyObject)")
            
            let lookBackDate = scanStartDate.addingTimeInterval(-scanDuration)
            var lastDeviceTime = Date()
            for otherManager in managers {
                for (uuid, info) in otherManager.value.teeth {
                    if info.utc > lookBackDate {
                        if let prevInfo = manager.teeth[uuid],
                            info.utc > prevInfo.utc {
                            continue
                        }
                        manager.teeth[uuid] = info
                        if info.utc < lastDeviceTime {
                            lastDeviceTime = info.utc
                        }
                    }
                }
            }
            
            
            DispatchQueue.global().asyncAfter(deadline: .now() + scanDuration - Date().timeIntervalSince(lastDeviceTime)) {
                BluetoothManager.queue.addOperation {
                    print("Async dispatch for \(scanStartDate as AnyObject)")
                    if let manager = managers[scanStartDate] {
                        manager.finish()
                        managers.removeValue(forKey: scanStartDate)
                        print("Removed bluetoothmanager for \(scanStartDate as AnyObject)")
                    }
                }
            }
        }
    }
    
    static func addTooth(peripheral: CBPeripheral, rssi: NSNumber) {
        print("Found tooth device:\(peripheral.name ?? "unknown")")
        for (_, manager) in managers {
            if manager.teeth[peripheral.identifier.uuidString] == nil {
                manager.teeth[peripheral.identifier.uuidString] = BluetoothInfo(utc: Date(), uuid: peripheral.identifier.uuidString, name: peripheral.name ?? "unknown", rssi: rssi)
            }
        }
    }
    
}

