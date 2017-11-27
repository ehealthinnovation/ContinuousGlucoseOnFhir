//
//  Int+Extension.swift
//  Pods
//
//  Created by Kevin Tallevi on 7/13/16.
//
//

// Reference: https://github.com/uraimo/Bitter/blob/master/Sources/Bitter/Bitter.swift


import Foundation

extension Int {
    // Perform a bit pattern truncating conversion to UInt8
    public var toU8: UInt8{return UInt8(truncatingIfNeeded:self)}
    // Perform a bit pattern truncating conversion to Int8
    public var to8: Int8{return Int8(truncatingIfNeeded:self)}
    // Perform a bit pattern truncating conversion to UInt16
    public var toU16: UInt16{return UInt16(truncatingIfNeeded:self)}
    // Perform a bit pattern truncating conversion to Int16
    public var to16: Int16{return Int16(truncatingIfNeeded:self)}
    // Perform a bit pattern truncating conversion to UInt32
    public var toU32: UInt32{return UInt32(truncatingIfNeeded:self)}
    // Perform a bit pattern truncating conversion to Int32
    public var to32: Int32{return Int32(truncatingIfNeeded:self)}
    // Perform a bit pattern truncating conversion to UInt64
    public var toU64: UInt64{
        return UInt64(self) //No difference if the platform is 32 or 64
    }
    // Perform a bit pattern truncating conversion to Int64
    public var to64: Int64{
        return Int64(self) //No difference if the platform is 32 or 64
    }
    // Perform a bit pattern truncating conversion to Int
    public var toInt:Int{return self}
    // Perform a bit pattern truncating conversion to UInt
    public var toUInt:UInt{return UInt(bitPattern:self)}
    
    // Returns the size of this type (number of bytes)
    public static var size:Int{return MemoryLayout<Int>.stride}
    
    public func bit(_ bit:Int) -> Int {
        if(Int.size == 8){
            return Int(bitPattern: UInt( (self.toU64 & (0x1 << bit.toU64)) >> bit.toU64 ))
        } else {
            return Int(bitPattern: UInt( (self.toU32 & (0x1 << bit.toU32)) >> bit.toU32 ))
        }
    }
    
    public func toBool () -> Bool? {
        switch self {
        case 0:
            return false
        case 1:
            return true
        default:
            return nil
        }
    }
}
