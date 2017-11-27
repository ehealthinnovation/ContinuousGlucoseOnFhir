//
//  BluetoothDateTime.swift
//  Pods
//
//  Created by Kevin Tallevi on 6/6/17.
//
//

import Foundation
import CCToolbox

public class BluetoothDateTime : NSObject {
    private var yearRange = NSRange(location:0, length: 2)
    private var monthRange = NSRange(location:2, length: 1)
    private var dayRange = NSRange(location:3, length: 1)
    private var hoursRange = NSRange(location:4, length: 1)
    private var minutesRange = NSRange(location:5, length: 1)
    private var secondsRange = NSRange(location:6, length: 1)
    private var timeZoneByteRange = NSRange(location:7, length: 1)
    private var dstOffsetByteRange = NSRange(location:8, length: 1)
    let timeZoneStepSizeMin60: Int = 4
    let minutesInHour: UInt8 = 60
    let secondsInMinute: UInt8 = 60
    var secondsInHour: Int = 3600
    
    enum dst: Int {
        case DSTStandardTime    = 0,
        DSTPlusHourHalf         = 2,
        DSTPlusHourOne          = 4,
        DSTPlusHoursTwo         = 8,
        DSTUnknown              = 255
    }
    
    public func timeZone() -> Int {
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        let timeZone = (secondsFromGMT / secondsInHour) * timeZoneStepSizeMin60
        
        return timeZone
    }
    
    public func dstOffset() -> Int {
        var daylightOffset: TimeInterval { return TimeZone.current.daylightSavingTimeOffset() }
        var dstOffsetValue: Int = dst.DSTUnknown.rawValue
        
        if (daylightOffset >= (Double(secondsInHour) * 2)) {
            dstOffsetValue = dst.DSTPlusHoursTwo.rawValue
        } else if (daylightOffset >= Double(secondsInHour)) {
            dstOffsetValue = dst.DSTPlusHourOne.rawValue
        } else if (daylightOffset >= Double(secondsInHour) / 2) {
            dstOffsetValue = dst.DSTPlusHourHalf.rawValue
        } else if (daylightOffset == 0) {
            dstOffsetValue = dst.DSTStandardTime.rawValue
        }
        
        return dstOffsetValue
    }

    public func dateFromData(data: NSData) -> Date {
        var dateComponents = DateComponents()
        
        let year = (data.subdata(with: yearRange) as NSData)
        let swappedYear = year.swapUInt16Data()
        dateComponents.year = Int(strtoul(swappedYear.toHexString(), nil, 16))
        
        let month = (data.subdata(with: monthRange) as NSData)
        dateComponents.month = Int(strtoul(month.toHexString(), nil, 16))
        
        let day = (data.subdata(with: dayRange) as NSData)
        dateComponents.day = Int(strtoul(day.toHexString(), nil, 16))
        
        let hours = (data.subdata(with: hoursRange) as NSData)
        dateComponents.hour = Int(strtoul(hours.toHexString(), nil, 16))
        
        let minutes = (data.subdata(with: minutesRange) as NSData)
        dateComponents.minute = Int(strtoul(minutes.toHexString(), nil, 16))
        
        let seconds = (data.subdata(with: secondsRange) as NSData)
        dateComponents.second = Int(strtoul(seconds.toHexString(), nil, 16))
        
        // assume the date includes time zone and dst offset bytes
        if(data.length > 7) {
            let timeZoneData: NSData = (data.subdata(with: timeZoneByteRange) as NSData)
            var timeZoneInt: NSInteger = 0
            timeZoneData.getBytes(&timeZoneInt, length: 1)
            if timeZoneInt != 0 {
                timeZoneInt = (((timeZoneInt - 256) / timeZoneStepSizeMin60) * secondsInHour)
            }
            let tz: TimeZone = NSTimeZone(forSecondsFromGMT: timeZoneInt) as TimeZone
        
            var dstOffsetInSeconds: TimeInterval!
            let dstOffsetCode = (data.subdata(with: dstOffsetByteRange) as NSData!)
            var dstOffset: NSInteger = 0
            dstOffsetCode?.getBytes(&dstOffset, length: 1)
        
            if ((dstOffset == dst.DSTStandardTime.rawValue) && (tz.daylightSavingTimeOffset() == 0)) {
                dstOffsetInSeconds = tz.daylightSavingTimeOffset()
            } else if ((dstOffset == dst.DSTPlusHourHalf.rawValue) && (Int(tz.daylightSavingTimeOffset()) != (secondsInHour / 2))) {
                dstOffsetInSeconds = TimeInterval(Int(tz.daylightSavingTimeOffset()) - (secondsInHour / 2))
            } else if ((dstOffset == dst.DSTPlusHourOne.rawValue) && (Int(tz.daylightSavingTimeOffset()) != secondsInHour)) {
                dstOffsetInSeconds = TimeInterval(Int(tz.daylightSavingTimeOffset()) - secondsInHour);
            } else if ((dstOffset == dst.DSTPlusHoursTwo.rawValue) && (Int(tz.daylightSavingTimeOffset()) != (secondsInHour * 2))) {
                dstOffsetInSeconds = TimeInterval(Int(tz.daylightSavingTimeOffset()) - (secondsInHour * 2));
            }
        
            dateComponents.second = dateComponents.second! - Int(dstOffsetInSeconds)
        }
        
        let measurementDate = NSCalendar.current.date(from: dateComponents as DateComponents)
        
        return measurementDate!
    }

    public func stringFromDate(date:Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        
        let str = dateFormatter.string(from: date)
        return str
    }
}
