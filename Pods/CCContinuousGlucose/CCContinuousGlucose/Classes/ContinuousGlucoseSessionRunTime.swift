//
//  ContinuousGlucoseSessionRunTime.swift
//  Pods
//
//  Created by Kevin Tallevi on 4/19/17.
//
// https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.cgm_session_run_time.xml

import Foundation
import CCToolbox

public class ContinuousGlucoseSessionRunTime : NSObject {
    public var runTime: UInt16 = 0
    
    init(data: NSData?) {
        super.init()
        let sessionRunTimeStr = data?.swapUInt16Data().toHexString()
        self.runTime = UInt16(strtoul(sessionRunTimeStr, nil, 16))
    }
}
