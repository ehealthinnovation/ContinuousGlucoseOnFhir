//
//  ContinuousGlucoseStatus.swift
//  Pods
//
//  Created by Kevin Tallevi on 4/18/17.
//
// https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.cgm_status.xml

import Foundation
import CCToolbox

public class ContinuousGlucoseStatus : NSObject {
    public var packetData: NSData?
    public var timeOffset: UInt16 = 0
    public var status: ContinuousGlucoseAnnunciation!
    public var e2eCRC: UInt16 = 0
    private let annunciationDataRange = NSRange(location:2, length: 3)
    
    init(data: NSData?) {
        super.init()
        self.packetData = data
        updateStatus(data: data)
    }
    
    public func updateStatus(data: NSData?) {
        data?.getBytes(&timeOffset, length: 2)
        
        let annunciationData = (data?.subdata(with: annunciationDataRange) as NSData!)
        self.status = ContinuousGlucoseAnnunciation(data: annunciationData)
    }
}
