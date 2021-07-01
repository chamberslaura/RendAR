//
//  CaptureRigPeripheral.swift
//  RendAR
//
//  Created by Laura Chambers on 2021-02-18.
//

import UIKit
import CoreBluetooth

class CaptureRigPeripheral: NSObject{
    
    public static let captureServiceUUID = CBUUID.init(string: "1101")
    public static let stateCharacteristicUUID = CBUUID.init(string: "2101")
    public static let massCharacteristicUUID = CBUUID.init(string: "4101")
}

