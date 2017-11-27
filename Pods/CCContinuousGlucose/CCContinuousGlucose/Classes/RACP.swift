//
//  RACP.swift
//  Pods
//
//  Created by Kevin Tallevi on 7/12/16.
//
//

import Foundation
import CCBluetooth
import CoreBluetooth

let reportStoredRecords =               "01"
let deleteStoredRecords =               "02"
let abortOperation =                    "03"
let reportNumberOfStoredRecords =       "04"
let numberOfStoredRecordsResponse =     "05"
let responseCode =                      "06"

var readNumberOfStoredRecords:String =  "0401"
var readAllStoredRecords:String =       "0101"
