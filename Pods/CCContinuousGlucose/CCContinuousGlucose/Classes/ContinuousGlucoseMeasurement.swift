//
//  ContinuousGlucoseMeasurement.swift
//  Pods
//
//  Created by Kevin Tallevi on 4/19/17.
//
// https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.cgm_measurement.xml

import Foundation
import CCToolbox

public class ContinuousGlucoseMeasurement : NSObject {
    public var packetData: NSData?
    public var packetSize: UInt16 = 0
    public var cgmTrendInformationPresent: Bool?
    public var cgmQualityPresent: Bool?
    public var sensorStatusAnnunciationFieldWarningOctetPresent: Bool?
    public var sensorStatusAnnunciationFieldCalTempOctetPresent: Bool?
    public var sensorStatusAnnunciationFieldStatusOctetPresent: Bool?
    public var glucoseConcentration: Float = 0
    public var timeOffset: Int = 0
    public var status: ContinuousGlucoseAnnunciation?
    public var trendValue: Float = 0
    public var quality: Float = 0
    
    private let flagsRange = NSRange(location:1, length: 1)
    private let glucoseConcentrationRange = NSRange(location:2, length: 2)
    private let timeOffsetRange = NSRange(location:4, length: 2)
    
    private var annunciationFieldSize: Int = 0
    private let annunciationLocation: Int = 6
    private var qualityRange: NSRange!
    
    private let cgmTrendInformationPresentBit = 0
    private let cgmQualityPresentBit = 1
    private let sensorStatusAnnunciationFieldWarningOctetPresentBit = 5
    private let sensorStatusAnnunciationFieldCalTempOctetPresentBit = 6
    private let sensorStatusAnnunciationFieldStatusOctetPresentBit = 7

    enum indexOffsets: Int {
        case size = 0,
        flags = 1,
        cgmGlucoseConcentration = 2,
        timeOffset = 4,
        sensorStatusAnnunciation = 6,
        cgmTrendInformation = 9,
        cgmQuality = 11,
        e2eCRC = 13
    }
    
    struct Flag {
        var position: Int?
        var value: Int?
        var dataLength: Int?
    }
    var flags: [Flag] = []
    
    enum FlagBytes: Int {
        case cgmTrendInformationPresent, cgmQualityPresent, sensorStatusAnnunciationFieldWarningOctetPresent, sensorStatusAnnunciationFieldCalTempOctetPresent, sensorStatusAnnunciationFieldStatusOctetPresent, count
    }

    
    init(data: NSData?) {
        super.init()
        
        self.packetData = data
        parseFlags()
        parseGlucoseConcentration()
        parseTimeOffset()
        parseAnnunciation()
        parseTrend()
        parseQuality()
    }
    
    func getOffset(max: Int) -> Int {
        //first 5 bytes are mandatory
        var offset: Int = 4
        
        for flag in flags {
            if flag.value == 1 {
                offset += flag.dataLength!
            }
        }
        
        if offset >= max {
            return max
        }
        
        return offset
    }
    
    func flagPresent(flagByte: Int) -> Int {
        for flag in flags {
            if flag.position == flagByte {
                return flag.value!
            }
        }
        
        return 0
    }

    func parseFlags() {
        let flagsData = packetData?.subdata(with: flagsRange) as NSData!
        let flagsString = flagsData?.toHexString()
        let flagsByte = Int(strtoul(flagsString, nil, 16))
        print("flags byte: \(flagsByte)")
        
        self.flags.append(Flag(position: FlagBytes.cgmTrendInformationPresent.rawValue, value: flagsByte.bit(0), dataLength: 2))
        self.flags.append(Flag(position: FlagBytes.cgmQualityPresent.rawValue, value: flagsByte.bit(1), dataLength: 2))
        self.flags.append(Flag(position: FlagBytes.sensorStatusAnnunciationFieldWarningOctetPresent.rawValue, value: flagsByte.bit(5), dataLength: 1))
        self.flags.append(Flag(position: FlagBytes.sensorStatusAnnunciationFieldCalTempOctetPresent.rawValue, value: flagsByte.bit(6), dataLength: 1))
        self.flags.append(Flag(position: FlagBytes.sensorStatusAnnunciationFieldStatusOctetPresent.rawValue, value: flagsByte.bit(7), dataLength: 1))
    }
    
    func parseGlucoseConcentration() {
        let glucoseConcentrationData = packetData?.subdata(with: glucoseConcentrationRange) as NSData!
        self.glucoseConcentration = (glucoseConcentrationData?.shortFloatToFloat())!
        
        print("glucose concentration: \(glucoseConcentration)")
    }
    
    func parseTimeOffset() {
        let timeOffsetData: NSData = packetData?.subdata(with: timeOffsetRange) as NSData!
        let timeOffsetString = timeOffsetData.swapUInt16Data().toHexString()
        let timeOffsetByte = Int(strtoul(timeOffsetString, nil, 16))
        self.timeOffset = timeOffsetByte
        
        print("time offset: \(timeOffset)")
    }

    func parseAnnunciation() {
        self.annunciationFieldSize = self.flagPresent(flagByte: FlagBytes.sensorStatusAnnunciationFieldWarningOctetPresent.rawValue) +
            self.flagPresent(flagByte: FlagBytes.sensorStatusAnnunciationFieldCalTempOctetPresent.rawValue) +
            self.flagPresent(flagByte: FlagBytes.sensorStatusAnnunciationFieldStatusOctetPresent.rawValue)
        
        let annunciationRange = NSRange(location: annunciationLocation, length: annunciationFieldSize)
        if annunciationFieldSize > 0 {
            print("annunciation: present")
            let annunciationData = packetData?.subdata(with: annunciationRange) as NSData!
            self.status = ContinuousGlucoseAnnunciation(data: annunciationData)
        } else {
            print("annunciation: not present")
        }
    }
    
    func parseTrend() {
        if self.flagPresent(flagByte: FlagBytes.cgmTrendInformationPresent.rawValue).toBool()! {
            let offset: Int = getOffset(max: 6 + self.annunciationFieldSize)

            print("parseTrend - offset: \(offset)")
            
            let trendRange = NSRange(location: offset, length: 2)
            let trendData = packetData?.subdata(with: trendRange) as NSData!
            trendValue = (trendData?.shortFloatToFloat())!
            print("trend [(mg/dL)/min]: \(trendValue)")
        } else {
            print("trend not present")
        }
    }
    
    func parseQuality() {
        if self.flagPresent(flagByte: FlagBytes.cgmQualityPresent.rawValue).toBool()! {
            let offset: Int = getOffset(max: 8 + self.annunciationFieldSize)
            print("parseQuality - offset: \(offset)")
            
            let qualityRange = NSRange(location: offset, length: 2)
            let qualityData = packetData?.subdata(with: qualityRange) as NSData!
            quality = (qualityData?.shortFloatToFloat())!
            print("quality(%): \(quality)")
        } else {
            print("quality not present")
        }
    }
    
    public func toMMOL() -> Float? {
        return (self.glucoseConcentration / 18);
    }
}
