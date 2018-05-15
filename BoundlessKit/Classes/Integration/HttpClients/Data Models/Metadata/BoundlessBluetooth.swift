//
//  BoundlessBluetooth.swift
//  BoundlessKit
//
//  Created by Akash Desai on 4/11/18.
//

import Foundation
//import CoreBluetooth

internal class BoundlessBluetooth : NSObject {
    
    static let shared = BoundlessBluetooth()
    
//    fileprivate var bluetoothManager: BluetoothManager?
    
    fileprivate override init() {
        super.init()
//        bluetoothManager = BluetoothManager(delegate: self, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: 0])
//        bluetoothManager?.scan(completion: {_ in})
    }
    
    func getBluetooth(callback: @escaping([[String: Any]]?) -> Void) {
//        bluetoothManager?.scan(completion: callback) ?? {
            callback(nil)
//        }()
    }
    
}

//extension BoundlessBluetooth : CBPeripheralDelegate, CBCentralManagerDelegate {
//
//    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        bluetoothManager?.canScan = (central.state == .poweredOn)
//    }
//
//    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        bluetoothManager?.didDiscover(peripheral: peripheral, rssi: RSSI)
//    }
//
//}


//fileprivate class BluetoothManager : CBCentralManager {
//
//    typealias ScanFinishBlock = (([[String: Any]]?) -> Void)?
//    struct BluetoothSignalInfo {
//        var utc: Date
//        var uuid: String
//        var name: String
//        var rssi: NSNumber
//
//        var toJSON: [String: Any] {
//            return ["utc": Int64(1000*utc.timeIntervalSince1970),
//                    "uuid": uuid,
//                    "name": name,
//                    "rssi": rssi
//            ]
//        }
//    }
//
//    fileprivate var queue = OperationQueue()
//    private var queuedScanners = SynchronizedDictionary<Date, ([String: BluetoothSignalInfo], [ScanFinishBlock])>()
//
//    fileprivate let scanDuration = TimeInterval(5)
//    private var cachedSignals = [String: BluetoothSignalInfo]()
//    fileprivate var canScan: Bool? {
//        didSet {
//            if let canScan = canScan {
//                if canScan {
//                    self.scanForPeripherals(withServices: nil, options: nil)
//                } else {
//                    if isScanning { stopScan() }
//                    for key in queuedScanners.keys {
//                        finish(startDate: key)
//                    }
//                }
//            }
//        }
//    }
//
//    fileprivate func didDiscover(peripheral: CBPeripheral, rssi: NSNumber) {
//        //        print("Found bluetooth device:\(peripheral.name ?? "unknown")")
//        let signalInfo = BluetoothSignalInfo(utc: Date(), uuid: peripheral.identifier.uuidString, name: peripheral.name ?? "unknown", rssi: rssi)
//        cachedSignals[peripheral.identifier.uuidString] = signalInfo
//        for (key, queuedScan) in queuedScanners.valuesForKeys {
//            if queuedScan.0[signalInfo.uuid] == nil {
//                self.queuedScanners[key]?.0[signalInfo.uuid] = signalInfo
//            }
//        }
//    }
//
//    private func finish(startDate: Date) {
//        if let (signals, scanners) = queuedScanners[startDate] {
//            var signalsInfo = [[String: Any]]()
//            for (_, signal) in signals {
//                signalsInfo.append(signal.toJSON)
//            }
//            for block in scanners {
//                block?(signalsInfo)
//            }
//            self.queue.addOperation {
//                self.queuedScanners.removeValue(forKey: startDate)
//                //                print("Removed bluetooth teeth(\(devices.count)) for \(startDate as AnyObject)")
//                if self.queuedScanners.isEmpty && self.isScanning {
//                    self.stopScan()
//                    //                    BKLog.debug("Finished all scans, stopping bluetooth scan")
//                }
//            }
//        } else {
//            //            BKLog.debug("Couldn't find finish startDate")
//        }
//
//    }
//
//    func scan(completion: ScanFinishBlock) {
//        let now: Date = Date()
//        queue.addOperation {
//            //            print("Bluetoothmanager looking for devices with startDate \(now as AnyObject)")
//
//            // check if there is a previous scan that this can add on to
//            let earlyStartDate = now.addingTimeInterval(-self.scanDuration)
//            var currentScannerDate = now
//
//            // find a scan started within range
//            for scanner in self.queuedScanners.keys {
//                if earlyStartDate <= scanner && scanner <= currentScannerDate {
//                    currentScannerDate = scanner
//                }
//            }
//            // queue it up and go home
//            if let _ = self.queuedScanners[currentScannerDate] {
//                self.queuedScanners[currentScannerDate]?.1.append(completion)
//                return
//            }
//
//            // grab any previous devices before queueing the scan finisher handler
//            // and set the start date to the earliest cached signal's date
//            var cacheGrab = [String: BluetoothSignalInfo]()
//            var scannerDate = now
//            for signal in self.cachedSignals.values {
//                if earlyStartDate <= signal.utc {
//                    if let previous = cacheGrab[signal.uuid],
//                        previous.utc < signal.utc {
//                        continue
//                    }
//                    cacheGrab[signal.uuid] = signal
//                    if signal.utc < scannerDate {
//                        scannerDate = signal.utc
//                    }
//                }
//            }
//
//            if let canScan = self.canScan {
//                if canScan {
//                    guard self.queuedScanners[scannerDate] == nil else { // should never hit `else` but just in case
//                        self.queuedScanners[scannerDate]?.1.append(completion)
//                        return
//                    }
//                    self.queuedScanners[scannerDate] = (cacheGrab, [completion])
//                    if !self.isScanning { self.scanForPeripherals(withServices: nil, options: nil) }
//                    DispatchQueue.global().asyncAfter(deadline: .now() + self.scanDuration - Date().timeIntervalSince(scannerDate)) {
//                        self.queue.addOperation {
//                            self.finish(startDate: scannerDate)
//                        }
//                    }
//                } else {
//                    completion?(nil)
//                    return
//                }
//            } else {
//                guard self.queuedScanners[scannerDate] == nil else {
//                    self.queuedScanners[scannerDate]?.1.append(completion)
//                    return
//                }
//                self.queuedScanners[scannerDate] = (cacheGrab, [completion])
//                DispatchQueue.global().asyncAfter(deadline: .now() + self.scanDuration - Date().timeIntervalSince(scannerDate)) {
//                    self.queue.addOperation {
//                        self.finish(startDate: scannerDate)
//                    }
//                }
//            }
//        }
//    }
//}


