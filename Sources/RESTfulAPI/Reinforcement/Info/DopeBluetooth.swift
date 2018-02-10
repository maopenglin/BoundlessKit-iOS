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
    
    fileprivate let bluetoothManager = BluetoothManager(delegate: nil, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: 0])
    
    fileprivate override init() {
        super.init()
        bluetoothManager.delegate = self
        bluetoothManager.scan()
    }
    
    public func getBluetooth(callback: @escaping ([[String: Any]]?)->()) {
//        guard canGetBluetooth else {
//            callback(nil)
//            return
//        }
        
        bluetoothManager.scan(completion: callback)
    }
    
}

extension DopeBluetooth : CBPeripheralDelegate, CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothManager.canScan = (central.state == .poweredOn)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        bluetoothManager.addTooth(peripheral: peripheral, rssi: RSSI)
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
    
    
    
    fileprivate var canScan = false {
        didSet {
            if !canScan && isScanning {
                stopScan()
            }
        }
    }
    fileprivate var scanStartDate = Date()
    fileprivate var scanStopDate = Date()
    fileprivate let scanDuration: TimeInterval = 5
    fileprivate var scanCompleteQueue = OperationQueue()
    
    func scan(completion: (([[String: Any]]?) -> Void)? = nil) {
        guard canScan else {
            completion?(nil)
            return
        }
        
        let nowDate = Date()
        scanStopDate = nowDate.addingTimeInterval(scanDuration)
        
        if isScanning {
            if nowDate.addingTimeInterval(-scanDuration) >= scanStartDate {
                scanCompleteQueue.addOperation {
                    completion?(self.devices(from: nowDate.addingTimeInterval(-self.scanDuration), to: nowDate))
                }
            } else { // if scanStartDate.addingTimeInterval(scanDuration) > nowDate {
                if let _ = completion {
                    DispatchQueue.global().asyncAfter(deadline:.now() + nowDate.timeIntervalSince(scanStartDate.addingTimeInterval(scanDuration))) {
                        self.scanCompleteQueue.addOperation {
                            completion?(self.devices(from: self.scanStartDate, to: self.scanStartDate.addingTimeInterval(self.scanDuration)))
                        }
                    }
                }
            }
        } else {
            scanStartDate = nowDate
            scanForPeripherals(withServices: nil, options: nil)
            
            if let completion = completion {
                DispatchQueue.global().asyncAfter(deadline: .now() + scanDuration) {
                    self.scanCompleteQueue.addOperation {
                        completion(self.devices(from: nowDate, to: nowDate.addingTimeInterval(self.scanDuration)))
                    }
                }
            }
        }
    }
    
    func addTooth(peripheral: CBPeripheral, rssi: NSNumber) {
        if let oldTooth = teeth[peripheral.identifier.uuidString],
            oldTooth.utc >= scanStartDate {
            return
        } else {
            teeth[peripheral.identifier.uuidString] = BluetoothInfo(utc: Date(), uuid: peripheral.identifier.uuidString, name: peripheral.name ?? "unknown", rssi: rssi)
        }
        
        if Date() > scanStopDate && isScanning {
            stopScan()
        }
    }
    
    
    var teeth = [String: BluetoothInfo]()
    func devices(from start: Date, to end:Date) -> [[String: Any]] {
        self.scanStartDate = start
        var devices = [[String: Any]]()
        for (_, device) in teeth {
            if start <= device.utc && device.utc <= end {
                devices.append(device.info)
            }
        }
        return devices
    }
    
}

