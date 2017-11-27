//
//  Float+ExtensionForIEEE.swift
//  Pods
//
//  Created by Kevin Tallevi on 6/1/17.
//
// The complete SFLOAT definition and its precision is described in Annex F of the 11073-20601 standard.
// Note: MDER = Medical Device Encoding Rules as per IEEE

import Foundation

enum reservedSFloatValues : Int {
    case mderPositiveInfinity = 0x07FE,
         mderNaN = 0x07FF,
         mderNRes = 0x0800,
         mderReservedValue = 0x0801,
         mderNegativeInfinity = 0x0802
}

let reservedValue: UInt32 = 0x07FE
let mderSFloatMax = 20450000000.0
let mderFloatMax = 8.388604999999999e+133
let mderSFLoatEpsilon = 1e-8
let mderSFloatMantissaMax = 0x07FD
let mderSFloatExponentMax = 7
let mderSFloatExponentMin = -8
let mderSFloatPrecision = 10000


extension Float {
    public func floatToShortFloat() -> Float {
        var result: Float = Float(reservedSFloatValues.mderNaN.rawValue)
        
        if(self > Float(mderSFloatMax)) {
            return Float(reservedSFloatValues.mderPositiveInfinity.rawValue)
        } else if (self < Float(-mderFloatMax)) {
            return Float(reservedSFloatValues.mderNegativeInfinity.rawValue)
        } else if (self >= Float(-mderSFLoatEpsilon) && self <= Float(mderSFLoatEpsilon)) {
            return 0
        }
        
        let sgn: Double = self > 0 ? +1 : -1
        var mantissa: Double = fabs(Double(self))
        var exponent: Int8 = 0
        
        // scale up if number is too big
        while (mantissa > Double(mderSFloatMantissaMax)) {
            mantissa /= 10.0
            exponent+=1
            if (Double(exponent) > Double(mderSFloatExponentMax)) {
                if (sgn > 0) {
                    result = Float(reservedSFloatValues.mderPositiveInfinity.rawValue)
                } else {
                    result = Float(reservedSFloatValues.mderNegativeInfinity.rawValue)
                }
                
                return Float(result)
            }
        }
        
        // scale down if number is too small
        while (mantissa < 1) {
            mantissa *= 10
            exponent-=1
            if (Int(exponent) < mderSFloatExponentMin) {
                result = 0
                return Float(result)
            }
        }
        
        // scale down if number needs more precision
        var smantissa: Double = Darwin.round(mantissa * Double(mderSFloatPrecision))
        var rmantissa: Double = Darwin.round(mantissa) * Double(mderSFloatPrecision)
        var mdiff: Double = abs(smantissa - rmantissa)
        while (mdiff > 0.5 && exponent > Int8(mderSFloatExponentMin) &&
            (mantissa * 10) <= Double(mderSFloatMantissaMax)) {
                mantissa *= 10
                exponent-=1
                smantissa = Darwin.round(mantissa * Double(mderSFloatPrecision))
                rmantissa = Darwin.round(mantissa) * Double(mderSFloatPrecision)
                mdiff = abs(smantissa - rmantissa)
        }
        
        let int_mantissa: Int16 = Int16(Darwin.round(sgn * mantissa))
        
        let adjustedExponent: Int16 = Int16(exponent) & 0xF
        let shiftedExponent: UInt16 = UInt16(adjustedExponent) << 12
        let adjustedMantissa: UInt16 = UInt16(int_mantissa & 0xFFF)
        let output = UInt16(adjustedMantissa) | shiftedExponent
        
        return Float(output)
    }
    
    public func floatToShortFloatAsData() -> NSData {
        let sFloat: UInt16 = UInt16(floatToShortFloat())
        var bytes:[UInt8] = []
        bytes.append(UInt8(sFloat & 0x00ff))
        bytes.append(UInt8(sFloat >> 8))
        
        let sFloatData = NSData(bytes: bytes, length: bytes.count)
        return sFloatData
    }
}
