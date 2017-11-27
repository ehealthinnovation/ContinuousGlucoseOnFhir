//
//  CGMViewController.swift
//  CCContinuousGlucose
//
//  Created by ktallevi on 04/06/2017.
//  Copyright (c) 2017 ktallevi. All rights reserved.
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
// swiftlint:disable nesting
// swiftlint:disable line_length
// swiftlint:disable file_length

import Foundation
import UIKit
import CoreBluetooth
import CCContinuousGlucose
import SMART

class CGMViewController: UITableViewController {
    var selectedMeter: CBPeripheral!
    let cellIdentifier = "CGMCellIdentifier"
    let sectionHeaderHeight: CGFloat = 75
    var continuousGlucoseFeatures: ContinuousGlucoseFeatures!
    var continuousGlucoseStatus: ContinuousGlucoseStatus!
    var glucoseMeasurementCount: UInt16 = 0
    var sessionRunTime: UInt16 = 0
    var continuousGlucoseMeterConnected: Bool = false
    
    enum Section: Int {
        case patient, device, session, features, cgmType, cgmSampleLocation, status, timeOffset, numberOfRecords, specificOpsControlPoint, startTime, runTime, count
        
        public func description() -> String {
            switch self {
                case .patient:
                    return "patient"
                case .device:
                    return "device"
                case .features:
                    return "features"
                case .cgmType:
                    return "cgm type"
                case .cgmSampleLocation:
                    return "cgm sample location"
                case .status:
                    return "status"
                case .timeOffset:
                    return "time offset"
                case .numberOfRecords:
                    return "number of records"
                case .specificOpsControlPoint:
                    return "specific ops control point"
                case .startTime:
                    return "start time"
                case .runTime:
                    return "run time"
                case .session:
                    return "session"
                case .count:
                    fatalError("invalid")
            }
        }
        
        public func rowCount() -> Int {
            switch self {
            case .patient:
                return Patient.count.rawValue
            case .device:
                return 1
            case .features:
                return 17
            case .cgmType:
                return 1
            case .cgmSampleLocation:
                return 1
            case .status:
                return 20
            case .timeOffset:
                return 1
            case .numberOfRecords:
                return 1
            case .specificOpsControlPoint:
                return 8
            case .startTime:
                return 1
            case .runTime:
                return 1
            case .session:
                return 1
            case .count:
                fatalError("invalid")
            }
        }
        enum Patient: Int {
            case patient, count
        }

        enum Device: Int {
            case name, manufacturerName, modelNumber, serialNumber, firmwareVersion, count
        }
        
        enum SpecificOpsControlPoint: Int {
            case getCGMCommunicationInterval, getGlucoseCalibrationValue, getPatientHighAlertLevel, getPatientLowAlertLevel, getHypoAlertLevel, getHyperAlertLevel, getRateOfDecreaseAlertLevel, getRateOfIncreaseAlertLevel
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ContinuousGlucose.sharedInstance().peripheral = selectedMeter
        ContinuousGlucose.sharedInstance().continuousGlucoseDelegate = self
        ContinuousGlucose.sharedInstance().connectToContinuousGlucoseMeter(continuousGlucoseMeter: selectedMeter)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.refreshTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.tableView.estimatedRowHeight = 70
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParentViewController {
            if self.continuousGlucoseMeterConnected {
               ContinuousGlucose.sharedInstance().disconnectContinuousGlucoseMeter()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
    }
    
    func showGlucoseCalibrationInformation() {
        var calibrationStr: String?
        if ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.continuousGlucoseCalibration != nil {
        calibrationStr = "Glucose Concentration: \(String(describing: ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.continuousGlucoseCalibration.calibrationValue!))mg/dl\n\r" +
        "Calibration Time: \(String(describing: ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.continuousGlucoseCalibration.calibrationTime!))min\n\r" +
        "Type: \(String(describing: ContinuousGlucose.CGMTypes(rawValue: ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.continuousGlucoseCalibration.calibrationType!)!.description))\n\r" +
        "Location: \(String(describing: ContinuousGlucose.CGMSampleLocations(rawValue: ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.continuousGlucoseCalibration.calibrationLocation!)!.description))\n\r" +
        "Next Calibration Time: \(String(describing: ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.continuousGlucoseCalibration.nextCalibrationTime!))min\n\r" +
        "Data Record Number: \(String(describing: ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.continuousGlucoseCalibration.calibrationDataRecordNumber!))"
        }
        
        let alertController = UIAlertController(title: "Calibration Information", message: calibrationStr, preferredStyle: .actionSheet)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true)
    }

    public func prepareSession() {
        ContinuousGlucose.sharedInstance().resetDeviceSpecificAlert()
        ContinuousGlucose.sharedInstance().setSessionStartTime()
        ContinuousGlucose.sharedInstance().setCommunicationInterval(minutes: 1)
        ContinuousGlucose.sharedInstance().setGlucoseCalibrationValue(glucoseConcentration: 120, calibrationTime: 10, type: 1, location: 1)
        ContinuousGlucose.sharedInstance().setPatientHighAlertLevel(level: 280)
        ContinuousGlucose.sharedInstance().setPatientLowAlertLevel(level: 100)
        ContinuousGlucose.sharedInstance().setHyperAlertLevel(level: 300)
        ContinuousGlucose.sharedInstance().setHypoAlertLevel(level: 90)
        ContinuousGlucose.sharedInstance().setRateOfDecreaseAlertLevel(glucoseConcentration: -1.0)
        ContinuousGlucose.sharedInstance().setRateOfIncreaseAlertLevel(glucoseConcentration: 1.0)
        ContinuousGlucose.sharedInstance().getSessionStartTime()
    }

    // MARK: table source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = Section(rawValue: section)
        return (sectionType?.rowCount())!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        cell.textLabel?.numberOfLines = 0
        
        switch indexPath.section {
        case Section.patient.rawValue:
            cell.textLabel!.text = "Given Name: \(CGMFhir.CGMFhirInstance.givenName)\nFamily Name: \(CGMFhir.CGMFhirInstance.familyName)"
            if CGMFhir.CGMFhirInstance.patient != nil {
                cell.detailTextLabel!.text = String(describing: "Patient FHIR ID: \(String(describing: CGMFhir.CGMFhirInstance.patient!.id!))")
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
            } else {
                if FHIR.fhirInstance.fhirServerAddress.isEmpty {
                    cell.detailTextLabel!.text = ""
                } else {
                    cell.detailTextLabel!.text = "Patient: Tap to upload"
                }
            }
        case Section.device.rawValue:
            if let manufacturer = ContinuousGlucose.sharedInstance().manufacturerName?.description {
                cell.textLabel!.text = "Manufacturer: \(manufacturer)"
            }
            if let modelNumber = ContinuousGlucose.sharedInstance().modelNumber?.description {
                cell.textLabel?.text?.append("\nModel: \(modelNumber)")
            }
            if CGMFhir.CGMFhirInstance.device != nil {
                cell.detailTextLabel!.text = String(describing: "Device FHIR ID: \(String(describing: CGMFhir.CGMFhirInstance.device!.id!))")
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
            } else {
                if FHIR.fhirInstance.fhirServerAddress.isEmpty {
                    cell.detailTextLabel!.text = ""
                } else {
                    cell.detailTextLabel!.text = "Device: Tap to upload"
                }
            }
        case Section.features.rawValue:
            if continuousGlucoseFeatures != nil {
                switch indexPath.row {
                    case ContinuousGlucoseFeatures.Features.calibrationSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.calibrationSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.calibrationSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.patientHighLowAlertsSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.patientHighLowAlertsSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.patientHighLowAlertsSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.hypoAlertsSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.hypoAlertsSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.hypoAlertsSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.hyperAlertsSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.hyperAlertsSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.hyperAlertsSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.rateOfIncreaseDecreaseAlertsSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.rateOfIncreaseDecreaseAlertsSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.rateOfIncreaseDecreaseAlertsSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.deviceSpecificAlertSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.deviceSpecificAlertSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.deviceSpecificAlertSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.sensorMalfunctionDetectionSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.sensorMalfunctionDetectionSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.sensorMalfunctionDetectionSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.sensorTemperatureHighLowDetectionSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.sensorTemperatureHighLowDetectionSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.sensorTemperatureHighLowDetectionSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.sensorResultHighLowDetectionSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.sensorResultHighLowDetectionSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.sensorResultHighLowDetectionSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.lowBatteryDetectionSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.lowBatteryDetectionSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.lowBatteryDetectionSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.sensorTypeErrorDetectionSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.sensorTypeErrorDetectionSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.sensorTypeErrorDetectionSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.generalDeviceFaultSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.generalDeviceFaultSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.generalDeviceFaultSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.e2eCRCSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.e2eCRCSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.e2eCRCSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.multipleBondSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.multipleBondSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.multipleBondSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.multipleSessionsSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.multipleSessionsSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.multipleSessionsSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.cgmTrendInformationSupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.cgmTrendInformationSupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.cgmTrendInformationSupported.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseFeatures.Features.cgmQualitySupported.rawValue:
                        cell.textLabel!.text = continuousGlucoseFeatures.cgmFeature.cgmQualitySupported?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseFeatures.Features.cgmQualitySupported.description
                        cell.accessoryType = .none
                    default:
                        cell.textLabel!.text = ""
                        cell.detailTextLabel!.text = ""
                        cell.accessoryType = .none
                }
            }
        case Section.cgmType.rawValue:
            cell.textLabel!.text =  ContinuousGlucose.CGMTypes(rawValue: continuousGlucoseFeatures.cgmFeature.cgmType!)!.description
            cell.detailTextLabel!.text = "type"
            cell.accessoryType = .none
        case Section.cgmSampleLocation.rawValue:
            cell.textLabel!.text =  ContinuousGlucose.CGMSampleLocations(rawValue: continuousGlucoseFeatures.cgmFeature.cgmSampleLocation!)!.description
            cell.detailTextLabel!.text = "location"
            cell.accessoryType = .none
        case Section.timeOffset.rawValue:
            cell.textLabel!.text = continuousGlucoseStatus.timeOffset.description
            cell.detailTextLabel!.text = "time offset"
            cell.accessoryType = .none
        case Section.numberOfRecords.rawValue:
            cell.textLabel!.text = glucoseMeasurementCount.description
            cell.detailTextLabel!.text = "records"
            cell.accessoryType = .none
        case Section.startTime.rawValue:
            cell.textLabel!.text = ContinuousGlucose.sharedInstance().sessionStartTime?.description
            cell.detailTextLabel!.text = "date"
            cell.accessoryType = .none
        case Section.runTime.rawValue:
            cell.textLabel!.text = self.sessionRunTime.description
            cell.detailTextLabel!.text = "minutes"
            cell.accessoryType = .none
        case Section.session.rawValue:
            cell.textLabel!.text = "start session"
            cell.detailTextLabel!.text = ""
            cell.accessoryType = .none
        case Section.specificOpsControlPoint.rawValue:
            switch indexPath.row {
                case Section.SpecificOpsControlPoint.getCGMCommunicationInterval.rawValue:
                    cell.textLabel!.text = ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.cgmCommunicationInterval.description
                    cell.detailTextLabel!.text = "communication interval (minutes)"
                    cell.accessoryType = .none
                case Section.SpecificOpsControlPoint.getGlucoseCalibrationValue.rawValue:
                    cell.textLabel!.text = "Tap for more information"
                    cell.detailTextLabel!.text = "glucose calibration value"
                    cell.accessoryType = .none
                case Section.SpecificOpsControlPoint.getPatientHighAlertLevel.rawValue:
                    cell.textLabel!.text = ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.patientHighAlertLevel.description
                    cell.detailTextLabel!.text = "patient high alert level"
                    cell.accessoryType = .none
                case Section.SpecificOpsControlPoint.getPatientLowAlertLevel.rawValue:
                    cell.textLabel!.text = ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.patientLowAlertLevel.description
                    cell.detailTextLabel!.text = "patient low alert level"
                    cell.accessoryType = .none
                case Section.SpecificOpsControlPoint.getHypoAlertLevel.rawValue:
                    cell.textLabel!.text = ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.hypoAlertLevel.description
                    cell.detailTextLabel!.text = "hypo alert level"
                    cell.accessoryType = .none
                case Section.SpecificOpsControlPoint.getHyperAlertLevel.rawValue:
                    cell.textLabel!.text = ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.hyperAlertLevel.description
                    cell.detailTextLabel!.text = "hyper alert level"
                    cell.accessoryType = .none
                case Section.SpecificOpsControlPoint.getRateOfDecreaseAlertLevel.rawValue:
                    cell.textLabel!.text = ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.rateOfDecreaseAlertLevel.description
                    cell.detailTextLabel!.text = "rate of decrease alert level"
                    cell.accessoryType = .none
                case Section.SpecificOpsControlPoint.getRateOfIncreaseAlertLevel.rawValue:
                    cell.textLabel!.text = ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.rateOfIncreaseAlertLevel.description
                    cell.detailTextLabel!.text = "rate of increase alert level"
                    cell.accessoryType = .none
                default:
                    cell.textLabel!.text = ""
                    cell.detailTextLabel!.text = ""
                    cell.accessoryType = .none
            }
        case Section.status.rawValue:
            if continuousGlucoseStatus != nil {
                switch indexPath.row {
                    case ContinuousGlucoseAnnunciation.Annunciation.sessionStopped.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sessionStopped?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sessionStopped.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.deviceBatteryLow.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.deviceBatteryLow?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.deviceBatteryLow.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorTypeIncorrectForDevice.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorTypeIncorrectForDevice?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorTypeIncorrectForDevice.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorMalfunction.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorMalfunction?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorMalfunction.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.deviceSpecificAlert.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.deviceSpecificAlert?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.deviceSpecificAlert.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.generalDeviceFaultHasOccurredInTheSensor.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.generalDeviceFaultHasOccurredInTheSensor?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.generalDeviceFaultHasOccurredInTheSensor.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.timeSynchronizationBetweenSensorAndCollectorRequired.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.timeSynchronizationBetweenSensorAndCollectorRequired?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.timeSynchronizationBetweenSensorAndCollectorRequired.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.calibrationNotAllowed.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.calibrationNotAllowed?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.calibrationNotAllowed.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.calibrationRecommended.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.calibrationRecommended?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.calibrationRecommended.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.calibrationRequired.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.calibrationRequired?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.calibrationRequired.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorTemperatureTooHighForValidTestResultAtTimeOfMeasurement.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorTemperatureTooHighForValidTestResultAtTimeOfMeasurement?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorTemperatureTooHighForValidTestResultAtTimeOfMeasurement.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorTemperatureTooLowForValidTestResultAtTimeOfMeasurement.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorTemperatureTooLowForValidTestResultAtTimeOfMeasurement?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorTemperatureTooLowForValidTestResultAtTimeOfMeasurement.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanThePatientLowLevel.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorResultLowerThanThePatientLowLevel?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanThePatientLowLevel.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanThePatientHighLevel.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorResultHigherThanThePatientHighLevel?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanThePatientHighLevel.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanTheHypoLevel.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorResultLowerThanTheHypoLevel?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanTheHypoLevel.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanTheHyperLevel.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorResultHigherThanTheHyperLevel?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanTheHyperLevel.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorRateOfDecreaseExceeded.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorRateOfDecreaseExceeded?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorRateOfDecreaseExceeded.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorRateOfIncreaseExceeded.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorRateOfIncreaseExceeded?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorRateOfIncreaseExceeded.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanTheDeviceCanProcess.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorResultLowerThanTheDeviceCanProcess?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanTheDeviceCanProcess.description
                        cell.accessoryType = .none
                    case ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanTheDeviceCanProcess.rawValue:
                        cell.textLabel!.text = continuousGlucoseStatus.status.sensorResultHigherThanTheDeviceCanProcess?.description
                        cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanTheDeviceCanProcess.description
                        cell.accessoryType = .none
                    default:
                        cell.textLabel!.text = ""
                        cell.detailTextLabel!.text = ""
                        cell.accessoryType = .none
                }
            }
        default:
            cell.textLabel!.text = ""
            cell.detailTextLabel!.text = ""
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.sectionHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionType = Section(rawValue: section)
        return sectionType?.description() ?? "none"
    }
    
    //MARK table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)! as UITableViewCell
        
        if indexPath.section == Section.session.rawValue {
            if FHIR.fhirInstance.fhirServerAddress.isEmpty {
                self.prepareSession()
                performSegue(withIdentifier: "segueToSession", sender: self)
            } else {
                if CGMFhir.CGMFhirInstance.patient == nil || CGMFhir.CGMFhirInstance.device == nil {
                    self.showAlert(title: "Patient and/or Device not uploaded", message: "Upload patient and/or device first")
                    return
                }

                self.prepareSession()
                performSegue(withIdentifier: "segueToSession", sender: self)
            }
        }
        
        if indexPath.section == Section.patient.rawValue {
            if !FHIR.fhirInstance.fhirServerAddress.isEmpty {
                if (CGMFhir.CGMFhirInstance.patient?.id) != nil {
                    performSegue(withIdentifier: "segueToPatient", sender: self)
                } else {
                    cell.accessoryView = self.createActivityView()
                    CGMFhir.CGMFhirInstance.createPatient { (patient, error) -> Void in
                        if error == nil {
                            print("patient created with id: \(String(describing: CGMFhir.CGMFhirInstance.patient!.id!))")
                            self.refreshTable()
                        }
                    }
                }
            }
        }
        
        if indexPath.section == Section.device.rawValue {
            if !FHIR.fhirInstance.fhirServerAddress.isEmpty {
                if (CGMFhir.CGMFhirInstance.device?.id) != nil {
                    performSegue(withIdentifier: "segueToDevice", sender: self)
                } else {
                    cell.accessoryView = self.createActivityView()
                    CGMFhir.CGMFhirInstance.createDevice { (device, error) -> Void in
                        if error == nil {
                            print("device created with id: \(String(describing: CGMFhir.CGMFhirInstance.device!.id!))")
                            self.refreshTable()
                            CGMFhir.CGMFhirInstance.createDeviceComponent { (error) -> Void in
                                if error == nil {
                                    print("device component created with id: \(String(describing: CGMFhir.CGMFhirInstance.deviceComponent!.id!))")
                                    self.refreshTable()
                                    CGMFhir.CGMFhirInstance.createSpecimen()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if indexPath.section == Section.specificOpsControlPoint.rawValue {
            if indexPath.row == Section.SpecificOpsControlPoint.getGlucoseCalibrationValue.rawValue {
                self.showGlucoseCalibrationInformation()
            }
        }
    }
    
    func createActivityView() -> UIActivityIndicatorView {
        let activity = UIActivityIndicatorView(frame: .zero)
        activity.sizeToFit()
        
        activity.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.gray
        activity.startAnimating()
        
        return activity
    }
    
    //MARK
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
            action.isEnabled = true
        })
        self.present(alert, animated: true)
    }
    
    // MARK: Storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToPatient" {
            let PatientViewVC =  segue.destination as! PatientViewController
            PatientViewVC.patient = CGMFhir.CGMFhirInstance.patient
        }
        if segue.identifier == "segueToDevice" {
            let DeviceViewVC =  segue.destination as! DeviceViewController
            DeviceViewVC.device = CGMFhir.CGMFhirInstance.device
        }
        if segue.identifier == "segueToSession" {
            let chartVC = segue.destination as! ChartViewController
            chartVC.hyperAlertLine = Double(ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.hyperAlertLevel)
            chartVC.hypoAlertLine = Double(ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.hypoAlertLevel)
            chartVC.patientHighLine = Double(ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.patientHighAlertLevel)
            chartVC.patientLowLine = Double(ContinuousGlucose.sharedInstance().continuousGlucoseSOCP.patientLowAlertLevel)
        }
    }

    func refreshTable() {
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
        
        if ContinuousGlucose.sharedInstance().serialNumber?.description != nil {
            DispatchQueue.once(executeToken: "continuousGlucose.refreshTable.runOnce") {
                if !FHIR.fhirInstance.fhirServerAddress.isEmpty {
                    self.searchForFHIRResources()
                }
            }
        }
    }
}

extension CGMViewController: ContinuousGlucoseProtocol {
    func continuousGlucoseSessionStartTimeUpdated() {
        print("continuousGlucoseSessionStartTimeUpdated")
        self.refreshTable()
    }

    func continuousGlucoseSOCPUpdated() {
        print("continuousGlucoseSOCPUpdated")
        self.refreshTable()
    }

    func continuousGlucoseSessionRunTime(runTime: UInt16) {
        print("CGMViewController#continuousGlucoseSessionRunTime - \(runTime)")
        self.sessionRunTime = runTime
    }

    func continuousGlucoseNumberOfStoredRecords(number: UInt16) {
        print("CGMViewController#numberOfStoredRecords - \(number)")
        glucoseMeasurementCount = number
        self.refreshTable()
    }

    func continuousGlucoseFeatures(features: ContinuousGlucoseFeatures) {
        print("CGMViewController#continuousGlucoseFeatures")
        continuousGlucoseFeatures = features
        
        self.refreshTable()
    }
    
    func continuousGlucoseStatus(status: ContinuousGlucoseStatus) {
        print("CGMViewController#continuousGlucoseStatus")
        continuousGlucoseStatus = status
        
        self.refreshTable()
    }
    
    func continuousGlucoseMeterConnected(meter: CBPeripheral) {
        continuousGlucoseMeterConnected = true
    }
    
    func continuousGlucoseMeterDisconnected(meter: CBPeripheral) {
        continuousGlucoseMeterConnected = false
    }
    
    //MARK
    public func searchForFHIRResources() {
        print("searchForFHIRResources")
        
        DispatchQueue.once(executeToken: "continuousGlucose.searchforFHIRResources.runOnce") {
            print("searching for patient \(CGMFhir.CGMFhirInstance.givenName) \(CGMFhir.CGMFhirInstance.familyName)")
            
            CGMFhir.CGMFhirInstance.searchForPatient(given: String(describing:  CGMFhir.CGMFhirInstance.givenName), family: String(describing: CGMFhir.CGMFhirInstance.familyName)) { (bundle, error) -> Void in
                if let error = error {
                    print("error searching for patient: \(error)")
                }
                
                if bundle?.entry != nil {
                    print("patient found")
                    self.refreshTable()
                    
                    CGMFhir.CGMFhirInstance.searchForDevice { (bundle, error) -> Void in
                        if let error = error {
                            print("error searching for device: \(error)")
                        }
                        
                        if bundle?.entry != nil {
                            print("device found")
                            self.refreshTable()
                            
                            CGMFhir.CGMFhirInstance.searchForSpecimen { (bundle, error) -> Void in
                                if let error = error {
                                    print("error searching for specimen: \(error)")
                                }
                                
                                if bundle?.entry != nil {
                                    print("specimen found")
                                }
                             }
                        } else {
                            print("device not found")
                        }
                    }
                } else {
                    print("patient not found")
                }
            }
        }
    }

}
