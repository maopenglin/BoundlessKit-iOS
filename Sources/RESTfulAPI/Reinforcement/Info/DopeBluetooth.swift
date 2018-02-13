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
        bluetoothManager.scan(completion: {_ in})
    }
    
    public func getBluetooth(callback: @escaping([[String: Any]]?) -> Void) {
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
    
    typealias ScanFinishBlock = (([[String: Any]]?) -> Void)?
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
    
    private var finishHandlers = [Date: ([String: BluetoothInfo], [ScanFinishBlock]) ]()
    private var devicesDiscovered = [String: BluetoothInfo]()
    
    fileprivate var queue = OperationQueue()
    fileprivate let scanDuration = TimeInterval(5)
    fileprivate var canScan: Bool? {
        didSet {
            if let canScan = canScan {
                if canScan {
                    self.scanForPeripherals(withServices: nil, options: nil)
                } else {
                    if isScanning { stopScan() }
                    for key in finishHandlers.keys {
                        finish(startDate: key)
                    }
                }
            }
        }
    }
    
    fileprivate func addTooth(peripheral: CBPeripheral, rssi: NSNumber) {
        print("Found tooth device:\(peripheral.name ?? "unknown")")
        let info = BluetoothInfo(utc: Date(), uuid: peripheral.identifier.uuidString, name: peripheral.name ?? "unknown", rssi: rssi)
        devicesDiscovered[peripheral.identifier.uuidString] = info
        for (key, finishHandler) in finishHandlers {
            if finishHandler.0[info.uuid] == nil {
                self.finishHandlers[key]?.0[info.uuid] = info
            }
        }
    }
    
    private func finish(startDate: Date) {
        if let (teeth, blocks) = finishHandlers[startDate] {
            var devices = [[String: Any]]()
            for (_, tooth) in teeth {
                devices.append(tooth.info)
            }
            for block in blocks {
                block?(devices)
            }
            self.queue.addOperation {
                self.finishHandlers.removeValue(forKey: startDate)
                print("Removed bluetooth teeth(\(devices.count)) for \(startDate as AnyObject)")
                if self.finishHandlers.isEmpty && self.isScanning {
                    self.stopScan()
                    DopeLog.debug("Finished all scans, stopping scan")
                }
            }
        } else {
            DopeLog.debug("Couldn't find finish startDate")
        }
        
    }
    
    func scan(startDate: Date = Date(), completion: ScanFinishBlock) {
        queue.addOperation {
            print("Bluetoothmanager looking for devices with startDate \(startDate as AnyObject)")
            
            // check if there is a previous scan that this can add on to
            let lookBackDate = startDate.addingTimeInterval(-self.scanDuration)
            var lastScanStart = startDate
            
            for date in self.finishHandlers.keys {
                if lookBackDate <= date && date <= lastScanStart {
                    lastScanStart = date
                }
            }
            if let _ = self.finishHandlers[lastScanStart] {
                self.finishHandlers[lastScanStart]?.1.append(completion)
                return
            }
            
            // grab any previous devices before creating new teeth
            var newTeeth = [String: BluetoothInfo]()
            var lastDiscoveryDate = startDate
            for (_, info) in self.devicesDiscovered {
                if lookBackDate <= info.utc {
                    if let prevInfo = newTeeth[info.uuid], prevInfo.utc < info.utc {
                        continue
                    }
                    newTeeth[info.uuid] = info
                    if info.utc < lastDiscoveryDate {
                        lastDiscoveryDate = info.utc
                    }
                }
            }
            
            if let canScan = self.canScan {
                if !canScan {
                    completion?(nil)
                    return
                } else {
                    self.finishHandlers[lastDiscoveryDate] = (newTeeth, [completion])
                    if !self.isScanning { self.scanForPeripherals(withServices: nil, options: nil) }
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.scanDuration - Date().timeIntervalSince(lastDiscoveryDate)) {
                        self.queue.addOperation {
                            self.finish(startDate: lastDiscoveryDate)
                        }
                    }
                }
            } else {
                self.finishHandlers[lastDiscoveryDate] = (newTeeth, [completion])
                DispatchQueue.global().asyncAfter(deadline: .now() + self.scanDuration - Date().timeIntervalSince(lastDiscoveryDate)) {
                    self.queue.addOperation {
                        self.finish(startDate: lastDiscoveryDate)
                    }
                }
            }
        }
    }
    
}

