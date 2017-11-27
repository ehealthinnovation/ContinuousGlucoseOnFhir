//
//  CGMFhir.swift
//  CCContinuousGlucose
//
//  Created by Kevin Tallevi on 6/13/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

// swiftlint:disable function_body_length
// swiftlint:disable line_length
// swiftlint:disable file_length

import Foundation
import CCContinuousGlucose
import SMART

public class CGMFhir: NSObject {
    static let CGMFhirInstance: CGMFhir = CGMFhir()
    var patient: Patient?
    var device: Device?
    var deviceComponent: DeviceComponent?
    var specimen: Specimen?
    var serialNumber: String!
    
    var givenName: FHIRString = "Lisa"
    var familyName: FHIRString = "Simpson"
    
    public func createPatient(callback: @escaping (_ patient: Patient, _ error: Error?) -> Void) {
        let patientName = HumanName()
        patientName.family = self.familyName
        patientName.given = [self.givenName]
        patientName.use = NameUse(rawValue: "official")
        
        let patientTelecom = ContactPoint()
        patientTelecom.use = ContactPointUse(rawValue: "work")
        patientTelecom.value = "4163404800"
        patientTelecom.system = ContactPointSystem(rawValue: "phone")
        
        let patientAddress = Address()
        patientAddress.city = "Toronto"
        patientAddress.country = "Canada"
        patientAddress.postalCode = "M5G2C4"
        patientAddress.line = ["585 University Ave"]
        
        let patientBirthDate = FHIRDate(string: DateTime.now.date.description)
        
        let patient = Patient()
        patient.active = true
        patient.name = [patientName]
        patient.telecom = [patientTelecom]
        patient.address = [patientAddress]
        patient.birthDate = patientBirthDate
        
        FHIR.fhirInstance.createPatient(patient: patient) { patient, error in
            if let error = error {
                print("error creating patient: \(error)")
            } else {
                self.patient = patient
            }
            callback(patient, error)
        }
    }
    
    public func searchForPatient(given: String, family: String, callback: @escaping FHIRSearchBundleErrorCallback) {
        print("GlucoseMeterViewController: searchForPatient")
        let searchDict: [String:Any] = [
            "given": given,
            "family": family
        ]
        
        FHIR.fhirInstance.searchForPatient(searchParameters: searchDict) { (bundle, error) -> Void in
            if let error = error {
                print("error searching for patient: \(error)")
            }
            
            if bundle?.entry != nil {
                let patients = bundle?.entry?
                    .filter { return $0.resource is Patient }
                    .map { return $0.resource as! Patient }
                    
                self.patient = patients?[0]
            }
            
            callback(bundle, error)
        }
    }
    
    public func createDeviceComponent(callback: @escaping (_ error: Error?) -> Void) {
        let deviceComponent = DeviceComponent()
        
        var productSpec = [DeviceComponentProductionSpecification]()
        var codingArray = [Coding]()
        
        //hardware revision
        let hardwareRevision = DeviceComponentProductionSpecification()
        hardwareRevision.productionSpec = FHIRString.init(ContinuousGlucose.sharedInstance().hardwareVersion!)
        
        let hardwareRevisionCoding = Coding()
        hardwareRevisionCoding.code = "hardware-revision"
        hardwareRevisionCoding.display = "Hardware Revision"
        hardwareRevisionCoding.system = FHIRURL.init("http://hl7.org/fhir/codesystem-specification-type.html")!
        codingArray.append(hardwareRevisionCoding)
        
        let hardwareRevisionCodableConcept = CodeableConcept()
        hardwareRevisionCodableConcept.coding = codingArray
        
        hardwareRevision.specType = hardwareRevisionCodableConcept
        productSpec.append(hardwareRevision)
        
        //software revision
        let softwareRevision = DeviceComponentProductionSpecification()
        softwareRevision.productionSpec = FHIRString.init(ContinuousGlucose.sharedInstance().softwareVersion!)
        
        let softwareRevisionCoding = Coding()
        softwareRevisionCoding.code = "software-revision"
        softwareRevisionCoding.display = "Software Revision"
        softwareRevisionCoding.system = FHIRURL.init("http://hl7.org/fhir/codesystem-specification-type.html")!
        codingArray.removeAll()
        codingArray.append(softwareRevisionCoding)
        
        let softwareRevisionCodableConcept = CodeableConcept()
        softwareRevisionCodableConcept.coding = codingArray
        
        softwareRevision.specType = softwareRevisionCodableConcept
        productSpec.append(softwareRevision)
        
        //firmware revision
        let firmwareRevision = DeviceComponentProductionSpecification()
        firmwareRevision.productionSpec = FHIRString.init(ContinuousGlucose.sharedInstance().firmwareVersion!)
        
        let firmwareRevisionCoding = Coding()
        firmwareRevisionCoding.code = "firmware-revision"
        firmwareRevisionCoding.display = "Firmware Revision"
        firmwareRevisionCoding.system = FHIRURL.init("http://hl7.org/fhir/codesystem-specification-type.html")!
        codingArray.removeAll()
        codingArray.append(firmwareRevisionCoding)
        
        let firmwareRevisionCodableConcept = CodeableConcept()
        firmwareRevisionCodableConcept.coding = codingArray
        
        firmwareRevision.specType = firmwareRevisionCodableConcept
        productSpec.append(firmwareRevision)
        deviceComponent.productionSpecification = productSpec
        
        let deviceReference = Reference()
        deviceReference.reference = FHIRString.init("Device/\(String(describing: self.device!.id!))")
        deviceComponent.source = deviceReference
        
        // device identifier (serial number)
        let deviceIdentifier = Identifier()
        deviceIdentifier.value = FHIRString.init(ContinuousGlucose.sharedInstance().serialNumber!)
        
        var deviceIdentifierCodingArray = [Coding]()
        let deviceIdentifierCoding = Coding()
        deviceIdentifierCoding.code = FHIRString.init("serial-number")
        deviceIdentifierCoding.display = FHIRString.init("Serial Number")
        deviceIdentifierCoding.system = FHIRURL.init("http://hl7.org/fhir/codesystem-specification-type.html")!
        deviceIdentifierCodingArray.append(deviceIdentifierCoding)
        
        let deviceIdentifierType = CodeableConcept()
        deviceIdentifierType.coding = deviceIdentifierCodingArray
        deviceIdentifier.type = deviceIdentifierType
        deviceComponent.identifier = deviceIdentifier
        
        // type
        var deviceCodingArray = [Coding]()
        let deviceCoding = Coding()
        deviceCoding.code = FHIRString.init("160368")
        deviceCoding.display = FHIRString.init("MDC_CONC_GLU_UNDETERMINED_PLASMA")
        deviceCoding.system = FHIRURL.init("urn.iso.std.iso:11073:10101")!
        deviceCodingArray.append(deviceCoding)
        
        let deviceType = CodeableConcept()
        deviceType.coding = deviceCodingArray
        deviceComponent.type = deviceType
        
        FHIR.fhirInstance.createDeviceComponent(deviceComponent: deviceComponent) { deviceComponent, error in
            if let error = error {
                print("error creating device: \(error)")
            } else {
                self.deviceComponent = deviceComponent
            }
            callback(error)
        }
    }
    
    public func createDevice(callback: @escaping (_ device: Device, _ error: Error?) -> Void) {
        let modelNumber = ContinuousGlucose.sharedInstance().modelNumber?.replacingOccurrences(of: "\0", with: "")
        let manufacturer = ContinuousGlucose.sharedInstance().manufacturerName!.replacingOccurrences(of: "\0", with: "")
        serialNumber = ContinuousGlucose.sharedInstance().serialNumber!.replacingOccurrences(of: "\0", with: "")
        
        let deviceCoding = Coding()
        deviceCoding.code = "337414009"
        deviceCoding.system = FHIRURL.init("http://snomed.info/sct")
        deviceCoding.display = "Blood glucose meters (physical object)"
        
        let deviceType = CodeableConcept()
        deviceType.coding = [deviceCoding]
        deviceType.text = "Glucose Meter"
        
        let deviceIdentifierTypeCoding = Coding()
        deviceIdentifierTypeCoding.system = FHIRURL.init("http://hl7.org/fhir/identifier-type")
        deviceIdentifierTypeCoding.code = "SNO"
        
        let deviceIdentifierType = CodeableConcept()
        deviceIdentifierType.coding = [deviceIdentifierTypeCoding]
        
        let deviceIdentifier = Identifier()
        deviceIdentifier.value = FHIRString.init(serialNumber)
        deviceIdentifier.type = deviceIdentifierType
        deviceIdentifier.system = FHIRURL.init("http://www.company.com/products/product/serial")
        
        let device = Device()
        device.status = FHIRDeviceStatus(rawValue: "available")
        device.manufacturer = FHIRString.init(manufacturer)
        device.model = FHIRString.init(modelNumber!)
        device.type = deviceType
        device.identifier = [deviceIdentifier]
        
        
        //Extension
        var deviceExtensionArray = [Extension]()
        let deviceExtensionContextURL: String = "https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.glucose_feature.xml"
        
        //Calibration Supported
        var extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.calibrationSupported?.description)!)
        
        extensionElementCoding.display = "Calibration Supported"
        
        var extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //Patient High/Low Alerts supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.patientHighLowAlertsSupported?.description)!)
        extensionElementCoding.display = "Patient High/Low Alerts supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)

        //Hypo Alerts supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.hypoAlertsSupported?.description)!)
        extensionElementCoding.display = "Hypo Alerts supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //Hyper Alerts supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.hyperAlertsSupported?.description)!)
        extensionElementCoding.display = "Hyper Alerts supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)

        //Rate of Increase/Decrease Alerts supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.rateOfIncreaseDecreaseAlertsSupported?.description)!)
        extensionElementCoding.display = "Rate of Increase/Decrease Alerts supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //Device Specific Alert supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.deviceSpecificAlertSupported?.description)!)
        extensionElementCoding.display = "Device Specific Alert supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //Sensor Malfunction Detection supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.sensorMalfunctionDetectionSupported?.description)!)
        extensionElementCoding.display = "Sensor Malfunction Detection supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //Sensor Temperature High-Low Detection supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.sensorTemperatureHighLowDetectionSupported?.description)!)
        extensionElementCoding.display = "Sensor Temperature High-Low Detection supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //Sensor Result High-Low Detection supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.sensorResultHighLowDetectionSupported?.description)!)
        extensionElementCoding.display = "Sensor Result High-Low Detection supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //Low Battery Detection supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.lowBatteryDetectionSupported?.description)!)
        extensionElementCoding.display = "Low Battery Detection supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //Sensor Type Error Detection supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.sensorTypeErrorDetectionSupported?.description)!)
        extensionElementCoding.display = "Sensor Type Error Detection supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //General Device Fault supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.generalDeviceFaultSupported?.description)!)
        extensionElementCoding.display = "General Device Fault supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //E2E-CRC supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.e2eCRCSupported?.description)!)
        extensionElementCoding.display = "E2E-CRC supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //Multiple Bond supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.multipleBondSupported?.description)!)
        extensionElementCoding.display = "Multiple Bond supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //Multiple Sessions supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.multipleSessionsSupported?.description)!)
        extensionElementCoding.display = "Multiple Sessions supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //CGM Trend Information supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.cgmTrendInformationSupported?.description)!)
        extensionElementCoding.display = "CGM Trend Information supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        //CGM Quality supported
        extensionElementCoding = Coding()
        extensionElementCoding.system = FHIRURL.init(deviceExtensionContextURL)
        extensionElementCoding.code = FHIRString.init((ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.cgmQualitySupported?.description)!)
        extensionElementCoding.display = "CGM Quality supported"
        
        extensionElement = Extension()
        extensionElement.url = FHIRURL.init(deviceExtensionContextURL)
        extensionElement.valueCoding = extensionElementCoding
        deviceExtensionArray.append(extensionElement)
        
        device.extension_fhir = deviceExtensionArray
        
        FHIR.fhirInstance.createDevice(device: device) { device, error in
            if let error = error {
                print("error creating device: \(error)")
            } else {
                self.device = device
            }
            callback(device, error)
        }
    }
    
    public func searchForDevice(callback: @escaping FHIRSearchBundleErrorCallback) {
        let modelNumber = ContinuousGlucose.sharedInstance().modelNumber?.replacingOccurrences(of: "\0", with: "")
        let manufacturer = ContinuousGlucose.sharedInstance().manufacturerName?.replacingOccurrences(of: "\0", with: "")
        
        let encodedModelNumber: String = modelNumber!.replacingOccurrences(of: " ", with: "+")
        let encodedMmanufacturer: String = manufacturer!.replacingOccurrences(of: " ", with: "+")
        
        let searchDict: [String:Any] = [
            "model": encodedModelNumber,
            "manufacturer": encodedMmanufacturer,
            "identifier": ContinuousGlucose.sharedInstance().serialNumber!
        ]
        
        FHIR.fhirInstance.searchForDevice(searchParameters: searchDict) { (bundle, error) -> Void in
            if let error = error {
                print("error searching for device: \(error)")
            }
            
            if bundle?.entry != nil {
                let devices = bundle?.entry?
                    .filter { return $0.resource is Device }
                    .map { return $0.resource as! Device }
                    
                    self.device = devices?[0]
            }
            
            callback(bundle, error)
        }
    }
    
    public func measurementToObservation(measurement: ContinuousGlucoseMeasurement) -> Observation {
        var codingArray = [Coding]()
        let coding = Coding()
        coding.system = FHIRURL.init("http://loinc.org")
        coding.code = "15074-8"
        coding.display = "Glucose [Moles/volume] in Blood"
        codingArray.append(coding)
        
        let codableConcept = CodeableConcept()
        codableConcept.coding = codingArray as [Coding]
        
        let deviceReference = Reference()
        deviceReference.reference = FHIRString.init("Device/\(String(describing: self.device!.id!))")
        
        let subjectReference = Reference()
        subjectReference.reference = FHIRString.init("Patient/\(String(describing: self.patient!.id!))")
        
        var performerArray = [Reference]()
        let performerReference = Reference()
        performerReference.reference = FHIRString.init("Patient/\(String(describing: self.patient!.id!))")
        performerArray.append(performerReference)
        
        let measurementNumber = NSDecimalNumber(value: self.truncateMeasurement(measurementValue: measurement.toMMOL()!))
        let decimalRoundingBehaviour = NSDecimalNumberHandler(roundingMode:.plain,
                                                              scale: 2, raiseOnExactness: false,
                                                              raiseOnOverflow: false, raiseOnUnderflow:
                                                              false, raiseOnDivideByZero: false)
        
        let quantity = Quantity.init()
        quantity.value = FHIRDecimal.init(String(describing: measurementNumber.rounding(accordingToBehavior: decimalRoundingBehaviour)))
        quantity.code = "mmol/L"
        quantity.system = FHIRURL.init("http://unitsofmeasure.org")
        quantity.unit = "mmol/L"
        
        let effectivePeriod = Period()
        
        let date: Date = (ContinuousGlucose.sharedInstance().sessionStartTime?.addingTimeInterval(TimeInterval(measurement.timeOffset * 60)))!
        effectivePeriod.start = DateTime(string: (date.iso8601))
        effectivePeriod.end = DateTime(string: (date.iso8601))
        
        let specimenReference = Reference()
        specimenReference.reference = FHIRString.init("Specimen/\(String(describing: self.specimen!.id!))")
        
        let observation = Observation.init()
        observation.status = ObservationStatus(rawValue: "final")
        observation.code = codableConcept
        observation.valueQuantity = quantity
        observation.effectivePeriod = effectivePeriod
        observation.device = deviceReference
        observation.subject = subjectReference
        observation.performer = performerArray
        observation.specimen = specimenReference
        
        if measurement.status != nil {
            //Extension
            var observationExtensionArray = [Extension]()
            let observationExtensionContextURL: String = "https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.cgm_measurement.xml"
            
            //Session Stopped
            var extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sessionStopped!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sessionStopped.description)
            
            var extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //Device Battery Low
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.deviceBatteryLow!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.deviceBatteryLow.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //sensorTypeIncorrectForDevice
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorTypeIncorrectForDevice!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorTypeIncorrectForDevice.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //sensorMalfunction
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorMalfunction!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorMalfunction.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)

            //deviceSpecificAlert
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.deviceSpecificAlert!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.deviceSpecificAlert.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //generalDeviceFaultHasOccurredInTheSensor
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.generalDeviceFaultHasOccurredInTheSensor!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.generalDeviceFaultHasOccurredInTheSensor.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //timeSynchronizationBetweenSensorAndCollectorRequired
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.timeSynchronizationBetweenSensorAndCollectorRequired!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.timeSynchronizationBetweenSensorAndCollectorRequired.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //calibrationNotAllowed
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.calibrationNotAllowed!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.calibrationNotAllowed.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //calibrationRecommended
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.calibrationRecommended!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.calibrationRecommended.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //calibrationRequired
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.calibrationRequired!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.calibrationRequired.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //sensorTemperatureTooHighForValidTestResultAtTimeOfMeasurement
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorTemperatureTooHighForValidTestResultAtTimeOfMeasurement!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorTemperatureTooHighForValidTestResultAtTimeOfMeasurement.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)

            //sensorTemperatureTooLowForValidTestResultAtTimeOfMeasurement
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorTemperatureTooLowForValidTestResultAtTimeOfMeasurement!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorTemperatureTooLowForValidTestResultAtTimeOfMeasurement.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //sensorResultLowerThanThePatientLowLevel
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorResultLowerThanThePatientLowLevel!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanThePatientLowLevel.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //sensorResultHigherThanThePatientHighLevel
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorResultHigherThanThePatientHighLevel!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanThePatientHighLevel.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //sensorResultLowerThanTheHypoLevel
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorResultLowerThanTheHypoLevel!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanTheHypoLevel.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)

            //sensorResultHigherThanTheHyperLevel
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorResultHigherThanTheHyperLevel!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanTheHyperLevel.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)

            //sensorRateOfDecreaseExceeded
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorRateOfDecreaseExceeded!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorRateOfDecreaseExceeded.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //sensorRateOfIncreaseExceeded
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorRateOfIncreaseExceeded!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorRateOfIncreaseExceeded.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //sensorResultLowerThanTheDeviceCanProcess
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorResultLowerThanTheDeviceCanProcess!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorResultLowerThanTheDeviceCanProcess.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //sensorResultHigherThanTheDeviceCanProcess
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init((String(describing: measurement.status?.sensorResultHigherThanTheDeviceCanProcess!.description)))
            extensionElementCoding.display = FHIRString.init(ContinuousGlucoseAnnunciation.Annunciation.sensorResultHigherThanTheDeviceCanProcess.description)
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //Trend
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init(String(describing: measurement.trendValue))
            extensionElementCoding.display = FHIRString.init("Trend")
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)

            //Quality
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init(String(describing: measurement.quality))
            extensionElementCoding.display = FHIRString.init("Quality")
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            observation.extension_fhir = observationExtensionArray
        } else {
            var observationExtensionArray = [Extension]()
            let observationExtensionContextURL: String = "https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.cgm_measurement.xml"
            
            //Trend
            var extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init(String(describing: measurement.trendValue))
            extensionElementCoding.display = FHIRString.init("Trend")
            
            var extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            //Quality
            extensionElementCoding = Coding()
            extensionElementCoding.system = FHIRURL.init(observationExtensionContextURL)
            extensionElementCoding.code = FHIRString.init(String(describing: measurement.quality))
            extensionElementCoding.display = FHIRString.init("Quality")
            
            extensionElement = Extension()
            extensionElement.url = FHIRURL.init(observationExtensionContextURL)
            extensionElement.valueCoding = extensionElementCoding
            observationExtensionArray.append(extensionElement)
            
            observation.extension_fhir = observationExtensionArray
        }
        
        return observation
    }
    
    public func truncateMeasurement(measurementValue: Float) -> Float {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = NumberFormatter.RoundingMode.down
        let truncatedValue = formatter.string(from: NSNumber(value: measurementValue))
        
        return Float(truncatedValue!)!
    }
    
    public func uploadSingleMeasurement(measurement: ContinuousGlucoseMeasurement) {
        if measurement.existsOnFHIR == false {
            FHIR.fhirInstance.createObservation(observation: self.measurementToObservation(measurement: measurement)) { (observation, error) -> Void in
                guard error == nil else {
                    print("error creating observation: \(String(describing: error))")
                    return
                }
                
                print("observation uploaded with id: \(observation.id!)")
                measurement.existsOnFHIR = true
                measurement.fhirID = String(describing: observation.id!)
            }
        }
    }
    
    func uploadObservationBundle(measurements: [ContinuousGlucoseMeasurement], callback: @escaping FHIRSearchBundleErrorCallback) {
        var pendingObservations: [Observation] = []
        var measurementArrayLocation: [Int] = []
        
        for i in 0...measurements.count - 1 {
            if measurements[i].existsOnFHIR == false {
                print("measurement pending: \(i)")
                pendingObservations.append(self.measurementToObservation(measurement: measurements[i]))
                measurementArrayLocation.append(i)
            }
        }
        
        if pendingObservations.count == 0 {
            return
        }
        
        FHIR.fhirInstance.createObservationBundle(observations: pendingObservations) { (bundle, error) -> Void in
            guard error == nil else {
                print("error creating observations: \(String(describing: error))")
                return
            }
            
            if let count = bundle?.entry?.count {
                //iterate through the batch response entries, start from 1 (zero is not a observation response)
                for i in 1...count-1 {
                    if bundle?.entry?[i].response?.status == "201 Created" {
                        let components = bundle?.entry?[i].response?.location?.absoluteString.components(separatedBy: "/")
                        measurements[measurementArrayLocation[i-1]].existsOnFHIR = true
                        measurements[measurementArrayLocation[i-1]].fhirID = components![1]
                        
                        print("observation uploaded with ID \(components![1])")
                    }
                }
            } else {
                print("problem uploading bundle, count is zero")
            }
            
            callback(bundle, error)
        }
    }
    
    public func createSpecimen() {
        let specimen = Specimen()
        let specimenCollection = SpecimenCollection()
        
        let bodySiteCoding = Coding()
        bodySiteCoding.system = FHIRURL.init("https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.cgm_feature.xml")
        bodySiteCoding.code = FHIRString.init(String(describing:ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.cgmSampleLocation!))
        bodySiteCoding.display = FHIRString.init((ContinuousGlucose.CGMSampleLocations(rawValue: ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.cgmSampleLocation!)!.description))
        
        let bodySite = CodeableConcept()
        bodySite.coding = [bodySiteCoding]
        specimenCollection.bodySite = bodySite
        specimen.collection = specimenCollection
        
        let deviceReference = Reference()
        deviceReference.reference = FHIRString.init("Device/\(String(describing: self.device!.id!))")
        specimen.subject = deviceReference
        
        let typeCoding = Coding()
        typeCoding.system = FHIRURL.init("https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.cgm_feature.xml")
        typeCoding.code = FHIRString.init(String(describing:ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.cgmType!))
        typeCoding.display = FHIRString.init((ContinuousGlucose.CGMTypes(rawValue: ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.cgmType!)!.description))
        
        let type = CodeableConcept()
        type.coding = [typeCoding]
        
        specimen.type = type
        
        FHIR.fhirInstance.createSpecimen(specimen: specimen) { (specimen, error) -> Void in
            guard error == nil else {
                print("error creating specimen: \(String(describing: error))")
                return
            }
            
            print("specimen uploaded with id: \(specimen.id!)")
            self.specimen = specimen
        }
    }
    
    public func searchForSpecimen(callback: @escaping FHIRSearchBundleErrorCallback) {
        print("GlucoseMeterViewController: searchForSpecimen")
        let bodySite: String = String(describing: ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.cgmSampleLocation!)
        let type = String(describing: ContinuousGlucose.sharedInstance().continuousGlucoseFeatures.cgmFeature.cgmType!)
        
        let searchDict: [String:Any] = [
            "bodysite": bodySite,
            "type": type,
            "subject": String(describing: "Device/\(self.device!.id!)")
        ]
        
        FHIR.fhirInstance.searchForSpecimen(searchParameters: searchDict) { (bundle, error) -> Void in
            if let error = error {
                print("error searching for specimen: \(error)")
            }
            
            if bundle?.entry == nil {
                
            } else {
                if bundle?.entry != nil {
                    let specimens = bundle?.entry?
                        .filter { return $0.resource is Specimen }
                        .map { return $0.resource as! Specimen }
                    
                    self.specimen = specimens?[0]
                }
            }
            callback(bundle, error)
        }
    }
}
