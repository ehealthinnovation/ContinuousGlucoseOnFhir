//
//  MeasurementDetailsViewController.swift
//  CCContinuousGlucose
//
//  Created by Kevin Tallevi on 5/8/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable nesting
// swiftlint:disable function_body_length

import Foundation
import UIKit
import CCContinuousGlucose

class MeasurementDetailsViewController: UITableViewController {
    let cellIdentifier = "MeasurementCellIdentifier"
    let sectionHeaderHeight: CGFloat = 75
    public var glucoseMeasurement: ContinuousGlucoseMeasurement!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    enum Section: Int {
        case data, fhir, details, annunciation, count
        
        public func description() -> String {
            switch self {
            case .data:
                return "data"
            case .fhir:
                return "fhir"
            case .details:
                return "details"
            case .annunciation:
                return "annunciation"
            case .count:
                fatalError("invalid")
            }
        }
        
        public func rowCount() -> Int {
            switch self {
            case .data:
                return 1
            case .fhir:
                return 2
            case .details:
                return 4
            case .annunciation:
                return 20
            case .count:
                fatalError("invalid")
            }
        }
        
        enum Fhir: Int {
            case existsOnFhir, FhirID, count
        }
        
        enum Details: Int {
            case glucoseConcentration, timeOffset, trendInformation, quality, count
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: table source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = Section(rawValue: section)
        return (sectionType?.rowCount())!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
    
        switch indexPath.section {
        case Section.data.rawValue:
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
            
            cell.textLabel!.text = glucoseMeasurement.packetData?.toHexString()
            cell.detailTextLabel!.text = "raw packet"
            
        case Section.fhir.rawValue:
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
            
            switch indexPath.row {
            case Section.Fhir.existsOnFhir.rawValue:
                cell.textLabel!.text = glucoseMeasurement.existsOnFHIR.description
                cell.detailTextLabel!.text = "exists on fhir"
            case Section.Fhir.FhirID.rawValue:
                cell.textLabel!.text = glucoseMeasurement.fhirID?.description
                cell.detailTextLabel!.text = "fhir id"
            default:
                print("")
            }
            
        case Section.details.rawValue:
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
            
            switch indexPath.row {
            case Section.Details.glucoseConcentration.rawValue:
                let mmolString = String(describing: CGMFhir.CGMFhirInstance.truncateMeasurement(measurementValue: glucoseMeasurement.toMMOL()!))
                cell.textLabel!.text = "\(glucoseMeasurement.glucoseConcentration.description) mg/dL (\(mmolString) mmol/L)"
                cell.detailTextLabel!.text = "glucose concentration"
            case Section.Details.timeOffset.rawValue:
                cell.textLabel!.text = glucoseMeasurement.timeOffset.description
                cell.detailTextLabel!.text = "time offset"
            case Section.Details.trendInformation.rawValue:
                cell.textLabel!.text = glucoseMeasurement.trendValue.description
                cell.detailTextLabel!.text = "trend information"
            case Section.Details.quality.rawValue:
                cell.textLabel!.text = glucoseMeasurement.quality.description
                cell.detailTextLabel!.text = "quality"
            default:
                print("")
            }
        case Section.annunciation.rawValue:
            if glucoseMeasurement.status == nil {
                cell.textLabel?.textColor = UIColor.gray
                cell.detailTextLabel?.textColor = UIColor.gray
            }
            
            switch indexPath.row {
            case ContinuousGlucoseAnnunciation.Annunciation.sessionStopped.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sessionStopped?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sessionStopped.description
            case ContinuousGlucoseAnnunciation.Annunciation.deviceBatteryLow.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.deviceBatteryLow?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.deviceBatteryLow.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorTypeIncorrectForDevice.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorTypeIncorrectForDevice?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorTypeIncorrectForDevice.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorMalfunction.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorMalfunction?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorMalfunction.description
            case ContinuousGlucoseAnnunciation.Annunciation.deviceSpecificAlert.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.deviceSpecificAlert?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.deviceSpecificAlert.description
            case ContinuousGlucoseAnnunciation.Annunciation.generalDeviceFaultHasOccurredInTheSensor.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.generalDeviceFaultHasOccurredInTheSensor?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.generalDeviceFaultHasOccurredInTheSensor.description
            case ContinuousGlucoseAnnunciation.Annunciation.timeSynchronizationBetweenSensorAndCollectorRequired.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.timeSynchronizationBetweenSensorAndCollectorRequired?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.timeSynchronizationBetweenSensorAndCollectorRequired.description
            case ContinuousGlucoseAnnunciation.Annunciation.calibrationNotAllowed.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.calibrationNotAllowed?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.calibrationNotAllowed.description
            case ContinuousGlucoseAnnunciation.Annunciation.calibrationRecommended.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.calibrationRecommended?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.calibrationRecommended.description
            case ContinuousGlucoseAnnunciation.Annunciation.calibrationRequired.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.calibrationRequired?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.calibrationRequired.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorTemperatureTooHighForValidTestResultAtTimeOfMeasurement.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorTemperatureTooHighForValidTestResultAtTimeOfMeasurement?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorTemperatureTooHighForValidTestResultAtTimeOfMeasurement.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorTemperatureTooLowForValidTestResultAtTimeOfMeasurement.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorTemperatureTooLowForValidTestResultAtTimeOfMeasurement?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorTemperatureTooLowForValidTestResultAtTimeOfMeasurement.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanThePatientLowLevel.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorResultLowerThanThePatientLowLevel?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanThePatientLowLevel.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanThePatientHighLevel.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorResultHigherThanThePatientHighLevel?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanThePatientHighLevel.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanTheHypoLevel.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorResultLowerThanTheHypoLevel?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanTheHypoLevel.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanTheHyperLevel.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorResultHigherThanTheHyperLevel?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanTheHyperLevel.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorRateOfDecreaseExceeded.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorRateOfDecreaseExceeded?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorRateOfDecreaseExceeded.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorRateOfIncreaseExceeded.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorRateOfIncreaseExceeded?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorRateOfIncreaseExceeded.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanTheDeviceCanProcess.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorResultLowerThanTheDeviceCanProcess?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanTheDeviceCanProcess.description
            case ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanTheDeviceCanProcess.rawValue:
                cell.textLabel!.text = glucoseMeasurement.status?.sensorResultHigherThanTheDeviceCanProcess?.description
                cell.detailTextLabel!.text = ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanTheDeviceCanProcess.description
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        default:
            print("")
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
    
    @IBAction func doneButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
