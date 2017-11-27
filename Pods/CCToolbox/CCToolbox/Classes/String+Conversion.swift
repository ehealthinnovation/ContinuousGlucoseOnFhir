//
//  NSString+Conversion.swift
//  Pods
//
//  Created by Kevin Tallevi on 7/8/16.
//
//

import Foundation

extension String {
    
    public func dataFromHexadecimalString() -> NSMutableData? {
        let data = NSMutableData(capacity: self.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, self.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.append(&num, length: 1)
        }
        
        return data
    }
    
    public func subStringWithRange(_ from:Int, to:Int) -> String {
        if let range = self.range(of: self) {
            let lo = self.index(range.lowerBound, offsetBy: from)
            let hi = self.index(range.lowerBound, offsetBy: to)
            let subRange = lo ..< hi
            
            return String(self[subRange])
        }
        
        return ""
    }
    
    public var dateFromISO8601: Date? {
        return Date.Formatter.iso8601.date(from: self)
    }
}

