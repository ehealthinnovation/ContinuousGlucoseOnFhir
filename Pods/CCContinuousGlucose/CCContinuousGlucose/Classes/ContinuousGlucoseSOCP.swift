//
//  ContinuousGlucoseSOCP.swift
//  Pods
//
//  Created by Kevin Tallevi on 4/19/17.
//
// https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.cgm_specific_ops_control_point.xml

import Foundation
import CoreBluetooth
import CCBluetooth

public class ContinuousGlucoseSOCP : NSObject {
    private let socpResponseOpCodeRange = NSRange(location:0, length: 1)
    
    private let cgmCommunicationIntervalRange = NSRange(location:1, length: 1)
    private let patientHighAlertLevelRange = NSRange(location:1, length: 2)
    private let patientLowAlertLevelRange = NSRange(location:1, length: 2)
    private let hypoAlertLevelRange = NSRange(location:1, length: 2)
    private let hyperAlertLevelRange = NSRange(location:1, length: 2)
    private let rateOfDecreaseAlertLevelRange = NSRange(location:1, length: 2)
    private let rateOfIncreaseAlertLevelRange = NSRange(location:1, length: 2)
    
    public var cgmCommunicationInterval: Int  = 0
    public var patientHighAlertLevel: UInt16 = 0
    public var patientLowAlertLevel: UInt16 = 0
    public var hypoAlertLevel: UInt16 = 0
    public var hyperAlertLevel: UInt16 = 0
    public var rateOfDecreaseAlertLevel: Float = 0
    public var rateOfIncreaseAlertLevel: Float = 0
    
    public var continuousGlucoseCalibration: ContinuousGlucoseCalibration!
    
    enum Fields: Int {
        case reserved,
        setCGMCommunicationInterval,
        getCGMCommunicationInterval,
        cgmCommunicationIntervalResponse,
        setGlucoseCalibrationValue,
        getGlucoseCalibrationValue,
        glucoseCalibrationValueResponse,
        setPatientHighAlertLevel,
        getPatientHighAlertLevel,
        patientHighAlertLevelResponse,
        setPatientLowAlertLevel,
        getPatientLowAlertLevel,
        patientLowAlertLevelResponse,
        setHypoAlertLevel,
        getHypoAlertLevel,
        hypoAlertLevelResponse,
        setHyperAlertLevel,
        getHyperAlertLevel,
        hyperAlertLevelResponse,
        setRateOfDecreaseAlertLevel,
        getRateOfDecreaseAlertLevel,
        rateOfDecreaseAlertLevelResponse,
        setRateOfIncreaseAlertLevel,
        getRateOfIncreaseAlertLevel,
        rateOfIncreaseAlertLevelResponse,
        resetDeviceSpecificAlert,
        startTheSession,
        stopTheSession,
        responseCode
    }

    public override init() {
        super.init()
    }

    public func parseSOCP(data: NSData) {
        let socpResponseType = (data.subdata(with: socpResponseOpCodeRange) as NSData!)
        var socpResponse: Int = 0
        socpResponseType?.getBytes(&socpResponse, length: 1)
        
        switch (socpResponse) {
            case ContinuousGlucoseSOCP.Fields.cgmCommunicationIntervalResponse.rawValue:
                let communicationIntervalData = (data.subdata(with: cgmCommunicationIntervalRange) as NSData!)
                communicationIntervalData?.getBytes(&self.cgmCommunicationInterval, length: 1)
                return
            case ContinuousGlucoseSOCP.Fields.glucoseCalibrationValueResponse.rawValue:
                self.continuousGlucoseCalibration = ContinuousGlucoseCalibration(data: data)
                return
            case ContinuousGlucoseSOCP.Fields.patientHighAlertLevelResponse.rawValue:
                let patientHighAlertLevelData = (data.subdata(with: patientHighAlertLevelRange) as NSData!)
                patientHighAlertLevelData?.getBytes(&self.patientHighAlertLevel, length: 2)
                return
            case ContinuousGlucoseSOCP.Fields.patientLowAlertLevelResponse.rawValue:
                let patientLowAlertLevelData = (data.subdata(with: patientLowAlertLevelRange) as NSData!)
                patientLowAlertLevelData?.getBytes(&self.patientLowAlertLevel, length: 2)
                return
            case ContinuousGlucoseSOCP.Fields.hypoAlertLevelResponse.rawValue:
                let hypoAlertLevelData = (data.subdata(with: hypoAlertLevelRange) as NSData!)
                hypoAlertLevelData?.getBytes(&self.hypoAlertLevel, length: 2)
                return
            case ContinuousGlucoseSOCP.Fields.hyperAlertLevelResponse.rawValue:
                let hyperAlertLevelData = (data.subdata(with: hyperAlertLevelRange) as NSData!)
                hyperAlertLevelData?.getBytes(&self.hyperAlertLevel, length: 2)
                return
            case ContinuousGlucoseSOCP.Fields.rateOfDecreaseAlertLevelResponse.rawValue:
                let rateOfDecreaseAlertLevelData = (data.subdata(with: rateOfDecreaseAlertLevelRange) as NSData!)
                self.rateOfDecreaseAlertLevel = (rateOfDecreaseAlertLevelData?.shortFloatToFloat())!
                return
            case ContinuousGlucoseSOCP.Fields.rateOfIncreaseAlertLevelResponse.rawValue:
                let rateOfIncreaseAlertLevelData = (data.subdata(with: rateOfIncreaseAlertLevelRange) as NSData!)
                self.rateOfIncreaseAlertLevel = (rateOfIncreaseAlertLevelData?.shortFloatToFloat())!
                return
            default:
                return
        }
    }
}
