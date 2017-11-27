//
//  ContinuousGlucoseCalibration.swift
//  Pods
//
//  Created by Kevin Tallevi on 6/7/17.
//
//

import Foundation
import CCToolbox

public class ContinuousGlucoseCalibration : NSObject {
    private let calibrationValueRange = NSRange(location:1, length: 2)
    private let calibrationTimeRange = NSRange(location:3, length: 2)
    private let calibrationTypeAndSampleLocationRange = NSRange(location:5, length: 1)
    private let nextCalibrationTimeRange = NSRange(location:6, length: 2)
    private let calibrationDataRecordNumberRange = NSRange(location:8, length: 2)
    private let calibrationStatusRange = NSRange(location:10, length: 1)
    
    public var calibrationValue: Float?
    public var calibrationTime: Int?
    public var calibrationType: Int?
    public var calibrationLocation: Int?
    public var nextCalibrationTime: Int?
    public var calibrationDataRecordNumber: Int?
    public var calibrationStatus: Int?
    
    public init(data: NSData?) {
        super.init()
        
        let calibrationValueData = (data?.subdata(with: calibrationValueRange) as NSData!).swapUInt16Data()
        self.calibrationValue = Float(strtoul(calibrationValueData.toHexString(), nil, 16))
        
        let calibrationTimeData = (data?.subdata(with: calibrationTimeRange) as NSData!).swapUInt16Data()
        self.calibrationTime = Int(strtoul(calibrationTimeData.toHexString(), nil, 16))
        
        let cgmTypeAndSampleLocationData = (data?.subdata(with: calibrationTypeAndSampleLocationRange) as NSData!)
        self.calibrationType = (cgmTypeAndSampleLocationData?.lowNibbleAtPosition())!
        self.calibrationLocation = (cgmTypeAndSampleLocationData?.highNibbleAtPosition())!
        
        let nextCalibrationTimeData = (data?.subdata(with: nextCalibrationTimeRange) as NSData!).swapUInt16Data()
        self.nextCalibrationTime = Int(strtoul(nextCalibrationTimeData.toHexString(), nil, 16))
        
        let calibrationDataRecordNumberData = (data?.subdata(with: calibrationDataRecordNumberRange) as NSData!).swapUInt16Data()
        self.calibrationDataRecordNumber = Int(strtoul(calibrationDataRecordNumberData.toHexString(), nil, 16))
        
        let calibrationStatusData = (data?.subdata(with: calibrationStatusRange) as NSData!)
        calibrationStatusData?.getBytes(&calibrationStatus, length: 1)
    }
}
