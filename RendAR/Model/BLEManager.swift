//
//  BluetoothManager.swift
//  RendAR
//
//  Created by Laura Chambers on 2021-02-19.
//

import Foundation
import CoreBluetooth

extension Notification.Name {
    static let BLEDidConnect = Notification.Name("BLEDidConnect")
    static let stateDidUpdate = Notification.Name("stateDidUpdate")
    static let massDidUpdate = Notification.Name("massDidUpdate")
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    var stateChar: CBCharacteristic?
    var massChar: CBCharacteristic?
    var stateValue: UInt8?
    var massValue: UInt8?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.delegate = self
    }
  
    // CENTRAL MANAGER
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            print("Central scanning for", CaptureRigPeripheral.captureServiceUUID);
            centralManager.scanForPeripherals(withServices: [CaptureRigPeripheral.captureServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        self.centralManager.stopScan()
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.centralManager.connect(self.peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        if peripheral == self.peripheral {
            print("Connected to RendAR capture rig")
            peripheral.discoverServices([CaptureRigPeripheral.captureServiceUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.peripheral = nil
        print("Central scanning for", CaptureRigPeripheral.captureServiceUUID);
        centralManager.scanForPeripherals(withServices: [CaptureRigPeripheral.captureServiceUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
    }
    
    // PERIPHERAL
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let services = peripheral.services {
            for service in services {
                if service.uuid == CaptureRigPeripheral.captureServiceUUID {
                    print("Capture service found")
                    peripheral.discoverCharacteristics([CaptureRigPeripheral.stateCharacteristicUUID, CaptureRigPeripheral.massCharacteristicUUID], for: service)
                }
            }
        }
    }
    
    func subscribeToNotifications(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        peripheral.setNotifyValue(true, for: characteristic)
     }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == CaptureRigPeripheral.stateCharacteristicUUID {
                    print("State characteristic found")
                    stateChar = characteristic
                    subscribeToNotifications(peripheral: peripheral, characteristic: stateChar!)
                } else if characteristic.uuid == CaptureRigPeripheral.massCharacteristicUUID {
                    print("Mass characteristic found")
                    massChar = characteristic
                    subscribeToNotifications(peripheral: peripheral, characteristic: massChar!)
                    NotificationCenter.default.post(name: .BLEDidConnect, object: self)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                     didUpdateNotificationStateFor characteristic: CBCharacteristic,
                     error: Error?) {
        print("Enabling notify ", characteristic.uuid)
        
        if error != nil {
            print("Enable notify error")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                     didUpdateValueFor characteristic: CBCharacteristic,
                     error: Error?) {
        
        let value = characteristic.value
        print("State update received")
        if characteristic == stateChar {
            stateValue = value![0]
            print("State:", stateValue!)
            NotificationCenter.default.post(name: .stateDidUpdate, object: self)
        } else if characteristic == massChar {
            massValue = value![0]
            print("Mass = \(massValue!)")
            NotificationCenter.default.post(name: .massDidUpdate, object: self)
        }
    }
    
    // HELPERS
    func write(value: Data, characteristic: CBCharacteristic) {
        self.peripheral?.writeValue(value, for: characteristic, type: .withResponse)
     }
}
