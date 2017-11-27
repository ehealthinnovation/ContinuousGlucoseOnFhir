//
//  CBPeriperhal+Extension.swift
//  Pods
//
//  Created by Kevin Tallevi on 7/11/16.
//
//

import Foundation
import CoreBluetooth

extension CBPeripheral {
    public func findCharacteristicByUUID(_ uuid:String) -> CBCharacteristic? {
        for service:CBService in self.services! {
            for characteristic:CBCharacteristic in service.characteristics! {
                if (characteristic.uuid.uuidString == uuid) {
                    return characteristic
                }
            }
        }
    
        return nil
    }
}
