//
//  Date+Extension.swift
//  Pods
//
//  Created by Kevin Tallevi on 9/22/16.
//
//

import Foundation

extension Date {
    struct Formatter {
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
            return formatter
        }()
    }
    
    public var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}
