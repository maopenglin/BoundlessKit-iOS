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
    
    fileprivate let bluetoothManager = BluetoothManager(delegate: nil, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: 0])
    public var canGetBluetooth: Bool = true
    fileprivate var lastScan = Date(timeIntervalSince1970: 0)
    fileprivate var timeAccuracy: TimeInterval = 5 //seconds
    
    fileprivate override init() {
        super.init()
        bluetoothManager.delegate = self
    }
    
    public func getBluetooth(delay: TimeInterval = 3, callback: @escaping ([String: Any]?)->()) {
        guard canGetBluetooth else {
            callback(nil)
            return
        }
        
        let now = Date()
        if now > lastScan.addingTimeInterval(timeAccuracy) {
            scan()
            lastScan = now
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                callback(self.bluetoothManager.teethInfo)
            }
        } else {
            callback(self.bluetoothManager.teethInfo)
        }
    }
    
}

extension DopeBluetooth : CBPeripheralDelegate, CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            
        case .poweredOn:
            canGetBluetooth = true
            
        case .poweredOff:
            canGetBluetooth = false
            
        default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        bluetoothManager.rememberDevice(peripheral: peripheral, rssi: RSSI)
        
        if Date() > lastScan.addingTimeInterval(timeAccuracy) {
            stopScan()
        }
    }
    
    func scan() {
        guard canGetBluetooth else {
            return
        }
        
        bluetoothManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan() {
        bluetoothManager.stopScan()
        bluetoothManager.teeth = [:]
    }
    
}


fileprivate class BluetoothManager : CBCentralManager {
    
    struct BluetoothInfo {
        var utc: Int64
        var uuid: String
        var name: String
        var rssi: NSNumber
        
        var info: [String: Any] {
            return ["utc": utc,
                    "uuid": uuid,
                    "name": name,
                    "rssi": rssi
            ]
        }
    }
    
    var teeth = [String: BluetoothInfo]()
    
    func rememberDevice(peripheral: CBPeripheral, rssi: NSNumber) {
        teeth[peripheral.identifier.uuidString] = BluetoothInfo(utc: Int64(Date().timeIntervalSince1970), uuid: peripheral.identifier.uuidString, name: peripheral.name ?? "unknown", rssi: rssi)
        
    }
    
    var teethInfo: [String: Any] {
        return Dictionary(uniqueKeysWithValues: teeth.map { uuid, tooth in (uuid, tooth.info)})
    }
    
}
