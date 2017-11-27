import Foundation
import CoreBluetooth
import CCBluetooth
import CCToolbox

var thisContinuousGlucose : ContinuousGlucose?

@objc public protocol ContinuousGlucoseProtocol {
    func continuousGlucoseNumberOfStoredRecords(number: UInt16)
    func continuousGlucoseFeatures(features:ContinuousGlucoseFeatures)
    func continuousGlucoseStatus(status:ContinuousGlucoseStatus)
    func continuousGlucoseMeterConnected(meter: CBPeripheral)
    func continuousGlucoseMeterDisconnected(meter: CBPeripheral)
    func continuousGlucoseSessionRunTime(runTime: UInt16)
    func continuousGlucoseSOCPUpdated()
    func continuousGlucoseSessionStartTimeUpdated()
}

@objc public protocol ContinuousGlucoseMeasurementProtocol {
    func continuousGlucoseMeasurement(measurement:ContinuousGlucoseMeasurement)
}

@objc public protocol ContinuousGlucoseMeterDiscoveryProtocol {
    func continuousGlucoseMeterDiscovered(continuousGlucoseMeter:CBPeripheral)
}

public class ContinuousGlucose : NSObject {
    public weak var continuousGlucoseDelegate : ContinuousGlucoseProtocol?
    public weak var continuousGlucoseMeterDiscoveryDelegate: ContinuousGlucoseMeterDiscoveryProtocol?
    public weak var continuousGlucoseMeasurementDelegate: ContinuousGlucoseMeasurementProtocol?
    public var peripheral : CBPeripheral? {
        didSet {
            if (peripheral != nil) {
                uuid = peripheral?.identifier.uuidString
                name = peripheral?.name
            }
        }
    }
    
    public var serviceUUIDString: String = "181F"
    public var autoEnableNotifications: Bool = true
    public var allowDuplicates: Bool = false
    public var batteryProfileSupported:Bool = false
    public var continuousGlucoseFeatures: ContinuousGlucoseFeatures!
    public var continuousGlucoseStatus: ContinuousGlucoseStatus!
    public var continuousGlucoseSOCP: ContinuousGlucoseSOCP!
    public var continuousGlucoseSessionRunTime: ContinuousGlucoseSessionRunTime!
    public var sessionStartTime: Date?

    var bluetoothDateTime: BluetoothDateTime!
    var peripheralNameToConnectTo : String?
    var servicesAndCharacteristics : [String: [CBCharacteristic]] = [:]
    var allowedToScanForPeripherals:Bool = false
    
    public var uuid: String?
    public var name: String?
    public var manufacturerName : String?
    public var modelNumber : String?
    public var serialNumber : String?
    public var firmwareVersion : String?
    public var hardwareVersion : String?
    public var softwareVersion : String?
    
    public let sessionRunTimeDataRange = NSRange(location:0, length: 2)
    
    
    @objc public enum CGMTypes : Int {
        case reserved = 0,
        capillaryWholeblood,
        capillaryPlasma,
        venousWholeBlood,
        venousPlasma,
        arterialWholeBlood,
        arterialPlasma,
        undeterminedWholeBlood,
        undeterminedPlasma,
        interstitialFluid,
        controlSolution
        
        public var description: String {
            switch self {
            case .capillaryWholeblood:
                return NSLocalizedString("Capillary Wholeblood", comment:"")
            case .capillaryPlasma:
                return NSLocalizedString("Capillary Plasma", comment:"")
            case .venousWholeBlood:
                return NSLocalizedString("Venous Whole Blood", comment:"")
            case .venousPlasma:
                return NSLocalizedString("Venous Plasma", comment:"")
            case .arterialWholeBlood:
                return NSLocalizedString("Arterial Whole Blood", comment:"")
            case .arterialPlasma:
                return NSLocalizedString("Arterial Plasma", comment:"")
            case .undeterminedWholeBlood:
                return NSLocalizedString("Undetermined Whole Blood", comment:"")
            case .undeterminedPlasma:
                return NSLocalizedString("Undetermined Plasma", comment:"")
            case .interstitialFluid:
                return NSLocalizedString("Interstitial Fluid", comment:"")
            case .controlSolution:
                return NSLocalizedString("Control Solution", comment:"")
            case .reserved:
                return NSLocalizedString("Reserved", comment:"")
            }
        }
        
        static let allValues = [reserved, capillaryWholeblood, capillaryPlasma, venousWholeBlood, venousPlasma, arterialWholeBlood, arterialPlasma, undeterminedWholeBlood, undeterminedPlasma, interstitialFluid, controlSolution]
    }
    
    @objc public enum CGMSampleLocations : Int {
        case reserved = 0,
        finger,
        alternateSiteTest,
        earlobe,
        controlSolution,
        subcutaneousTissue,
        sampleLocationValueNotAvailable
        
        public var description: String {
            switch self {
            case .finger:
                return NSLocalizedString("Finger", comment:"")
            case .alternateSiteTest:
                return NSLocalizedString("Alternate Site Test", comment:"")
            case .earlobe:
                return NSLocalizedString("Earlobe", comment:"")
            case .controlSolution:
                return NSLocalizedString("Control Solution", comment:"")
            case .subcutaneousTissue:
                return NSLocalizedString("Subcutaneous Tissue", comment:"")
            case .sampleLocationValueNotAvailable:
                return NSLocalizedString("Sample Location Value Not Available", comment:"")
            case .reserved:
                return NSLocalizedString("Reserved", comment:"")
            }
        }
        
        static let allValues = [reserved, finger, alternateSiteTest, earlobe, controlSolution, subcutaneousTissue, sampleLocationValueNotAvailable]
    }
    
    public class func sharedInstance() -> ContinuousGlucose {
        if thisContinuousGlucose == nil {
            thisContinuousGlucose = ContinuousGlucose()
        }
        return thisContinuousGlucose!
    }
    
    public override init() {
        super.init()
        self.configureBluetoothParameters()
        self.continuousGlucoseSOCP = ContinuousGlucoseSOCP()
        self.bluetoothDateTime = BluetoothDateTime()
    }
    
    func configureBluetoothParameters() {
        Bluetooth.sharedInstance().serviceUUIDString = "181F"
        Bluetooth.sharedInstance().allowDuplicates = false
        Bluetooth.sharedInstance().autoEnableNotifications = true
        Bluetooth.sharedInstance().bluetoothDelegate = self
        Bluetooth.sharedInstance().bluetoothPeripheralDelegate = self
        Bluetooth.sharedInstance().bluetoothServiceDelegate = self
        Bluetooth.sharedInstance().bluetoothCharacteristicDelegate = self
    }
    
    public func connectToContinuousGlucoseMeter(continuousGlucoseMeter: CBPeripheral) {
        Bluetooth.sharedInstance().stopScanning()
        Bluetooth.sharedInstance().connectPeripheral(continuousGlucoseMeter)
    }
    
    public func disconnectContinuousGlucoseMeter() {
        if let peripheral = self.peripheral {
            Bluetooth.sharedInstance().disconnectPeripheral(peripheral)
        }
    }
    
    func writeCharacteristic(characteristic:CBCharacteristic, data: Data) {
        Bluetooth.sharedInstance().writeCharacteristic(characteristic, data: data)
    }
    
    func crcIsValid(data: NSData) -> Bool {
        let packet = (data.subdata(with: NSRange(location:0, length: data.length - 2)) as NSData!)
        let packetCRC = (data.subdata(with: NSRange(location:data.length - 2, length: 2)) as NSData!)
        let calculatedCRC: NSData = (packet?.crcMCRF4XX)!
        
        if packetCRC == calculatedCRC {
            return true
        }
        
        return false
    }
    
    func parseFeaturesResponse(data: NSData) {
        self.continuousGlucoseFeatures = ContinuousGlucoseFeatures(data: data)
        continuousGlucoseDelegate?.continuousGlucoseFeatures(features: self.continuousGlucoseFeatures)
    }
    
    func parseCGMStatus(data: NSData) {
        self.continuousGlucoseStatus = ContinuousGlucoseStatus(data: data)
        continuousGlucoseDelegate?.continuousGlucoseStatus(status: self.continuousGlucoseStatus)
    }
    
    func parseCGMSessionRunTime(data: NSData) {
        let sessionRunTimeData = (data.subdata(with: sessionRunTimeDataRange) as NSData!)
        
        self.continuousGlucoseSessionRunTime = ContinuousGlucoseSessionRunTime(data: sessionRunTimeData)
        continuousGlucoseDelegate?.continuousGlucoseSessionRunTime(runTime: self.continuousGlucoseSessionRunTime.runTime)
    }
    
    func parseCGMSessionStartTime(data: NSData) {
        self.sessionStartTime = bluetoothDateTime.dateFromData(data: data)
        continuousGlucoseDelegate?.continuousGlucoseSessionStartTimeUpdated()
    }
    
    func parseCGMSOCP(data: NSData) {
        self.continuousGlucoseSOCP.parseSOCP(data: data)
        continuousGlucoseDelegate?.continuousGlucoseSOCPUpdated()
    }

    func parseGlucoseMeasurement(data: NSData) {
        let continuousGlucoseMeasurement = ContinuousGlucoseMeasurement(data: data)
        continuousGlucoseMeasurementDelegate?.continuousGlucoseMeasurement(measurement: continuousGlucoseMeasurement)
    }
    
    func parseRACPReponse(data:NSData) {
        let hexString = data.toHexString()
        let hexStringHeader = hexString.subStringWithRange(0, to: 2)
        
        if(hexStringHeader == numberOfStoredRecordsResponse) {
            let numberOfStoredRecordsStr = data.swapUInt16Data().toHexString().subStringWithRange(4, to: 8)
            let numberOfStoredRecords = UInt16(strtoul(numberOfStoredRecordsStr, nil, 16))
            continuousGlucoseDelegate?.continuousGlucoseNumberOfStoredRecords(number: numberOfStoredRecords)
        }
    }
    
    public func readNumberOfRecords() {
        let data = readNumberOfStoredRecords.dataFromHexadecimalString()
        
        if let characteristic = peripheral?.findCharacteristicByUUID(recordAccessControlPointCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: data! as Data)
        }
    }
    
    public func stringFromDate(date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let year =  components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let seconds = components.second
        
        var str = ""
        str += String(format:"%04X", UInt16(bigEndian: UInt16(year!)))
        str += String(format:"%02X", month!)
        str += String(format:"%02X", day!)
        str += String(format:"%02X", hour!)
        str += String(format:"%02X", minute!)
        str += String(format:"%02X", seconds!)
        
        return str
    }
    
    public func getSessionStartTime() {
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSessionStartTimeCharacteristic) {
            self.peripheral?.readValue(for: characteristic)
        }
    }
    
    public func setSessionStartTime() {
        let timeData = self.stringFromDate(date: Date()).dataFromHexadecimalString()
        var timeZoneInt = self.bluetoothDateTime.timeZone()
        let timeZoneData = Data(bytes: &timeZoneInt,
                                count: 1)
    
        var dstInt = self.bluetoothDateTime.dstOffset()
        let dstData = Data(bytes: &dstInt, count: 1)
        
        timeData?.append(timeZoneData)
        timeData?.append(dstData)
       
        let crc: NSData = (timeData?.crcMCRF4XX)!
        timeData?.append(crc as Data)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSessionStartTimeCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: timeData! as Data)
        }
    }
    
    public func stopSession() {
        let stopSessionData = Data(bytes: [0x1B, 0x00, 0x81, 0x81] as [UInt8], count: 4)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: stopSessionData)
        }
    }
    
    public func startSession() {
        let startSessionData = Data(bytes: [0x1A, 0x00, 0x59, 0x98] as [UInt8], count: 4)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: startSessionData)
        }
    }
    
    public func setCommunicationInterval(minutes: UInt8) {
        let packetCMD = [1, minutes]
        let packetData = NSMutableData(bytes: packetCMD, length: 2)
        
        let crc: NSData = packetData.crcMCRF4XX
        packetData.append(crc as Data)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: packetData as Data)
        }
    }
    
    public func getCommunicationInterval() {
        let getCommunicationIntervalData = Data(bytes: [0x02, 0x00, 0x08, 0xC3] as [UInt8], count: 4)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: getCommunicationIntervalData as Data)
        }
    }
    
    public func setGlucoseCalibrationValue(glucoseConcentration: Float, calibrationTime: Int16, type: Int, location: Int) {
        let packetData = NSMutableData(bytes: [0x04], length: 1)
        
        let glucoseConcentrationData: NSData = glucoseConcentration.floatToShortFloatAsData()
        packetData.append(glucoseConcentrationData as Data)
        
        let calibrationTimeStr = String(format:"%04X", calibrationTime)
        let calibrationTimeData = calibrationTimeStr.dataFromHexadecimalString()?.swapUInt16Data()
        packetData.append(calibrationTimeData! as Data)
        
        var typeLocation = (type << 4) | location
        let typeLocationData = Data(bytes: &typeLocation, count: 1)
        packetData.append(typeLocationData as Data)
        
        let ignoredBytes = [0x00, 0x00, 0x00, 0x00, 0x00]
        let ignoredBytesData = NSMutableData(bytes: ignoredBytes, length: ignoredBytes.count)
        packetData.append(ignoredBytesData as Data)
        
        let crc: NSData = packetData.crcMCRF4XX
        packetData.append(crc as Data)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: packetData as Data)
        }
    }
    
    public func getGlucoseCalibrationValue() {
        let getGlucoseCalibrationValueData = Data(bytes: [0x05, 0x01, 0x00, 0x56, 0x19] as [UInt8], count: 5)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: getGlucoseCalibrationValueData as Data)
        }
    }
    
    public func setPatientHighAlertLevel(level: UInt16) {
        let packetCMD = [7, UInt8(level & 0x00ff), UInt8(level >> 8)]
        let packetData = NSMutableData(bytes: packetCMD, length: packetCMD.count)
        
        let crc: NSData = packetData.crcMCRF4XX
        packetData.append(crc as Data)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: packetData as Data)
        }
    }
    
    public func getPatientHighAlertLevel() {
        let getPatientHighAlertLevelData = Data(bytes: [0x08, 0x00, 0x78, 0x3E] as [UInt8], count: 4)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: getPatientHighAlertLevelData)
        }
    }
    
    public func setPatientLowAlertLevel(level: UInt16) {
        let packetCMD = [10, UInt8(level & 0x00ff), UInt8(level >> 8)]
        let packetData = NSMutableData(bytes: packetCMD, length: packetCMD.count)
        
        let crc: NSData = packetData.crcMCRF4XX
        packetData.append(crc as Data)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: packetData as Data)
        }
    }
    
    public func getPatientLowAlertLevel() {
        let getPatientLowAlertLevelData = Data(bytes: [0x0B, 0x00, 0x10, 0x14] as [UInt8], count: 4)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: getPatientLowAlertLevelData)
        }
    }
    
    public func setHypoAlertLevel(level: UInt16) {
        let packetCMD = [13, UInt8(level & 0x00ff), UInt8(level >> 8)]
        let packetData = NSMutableData(bytes: packetCMD, length: packetCMD.count)
        
        let crc: NSData = packetData.crcMCRF4XX
        packetData.append(crc as Data)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: packetData as Data)
        }
    }
    
    public func getHypoAlertLevel() {
        let getHypoAlertLevelData = Data(bytes: [0x0E, 0x00, 0xA8, 0x6A] as [UInt8], count: 4)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: getHypoAlertLevelData)
        }
    }
    
    public func setHyperAlertLevel(level: UInt16) {
        let packetCMD = [16, UInt8(level & 0x00ff), UInt8(level >> 8)]
        let packetData = NSMutableData(bytes: packetCMD, length: packetCMD.count)
        
        let crc: NSData = packetData.crcMCRF4XX
        packetData.append(crc as Data)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: packetData as Data)
        }
    }
    
    public func getHyperAlertLevel() {
        let getHyperAlertLevelData = Data(bytes: [0x11, 0x00, 0xF1, 0x7C] as [UInt8], count: 4)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: getHyperAlertLevelData)
        }
    }
    
    public func setRateOfDecreaseAlertLevel(glucoseConcentration: Float) {
        let glucoseConcentrationData: NSData = glucoseConcentration.floatToShortFloatAsData()
        let packetData = NSMutableData(bytes: [0x13], length: 1)
        packetData.append(glucoseConcentrationData as Data)
        
        let crc: NSData = packetData.crcMCRF4XX
        packetData.append(crc as Data)

        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: packetData as Data)
        }
    }
    
    public func getRateOfDecreaseAlertLevel() {
        let getRateOfDecreaseAlertLevelData = Data(bytes: [0x14, 0x00, 0x49, 0x02] as [UInt8], count: 4)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: getRateOfDecreaseAlertLevelData)
        }
    }
    
    public func setRateOfIncreaseAlertLevel(glucoseConcentration: Float) {
        let glucoseConcentrationData: NSData = glucoseConcentration.floatToShortFloatAsData()
        let packetData = NSMutableData(bytes: [0x16], length: 1)
        packetData.append(glucoseConcentrationData as Data)
        
        let crc: NSData = packetData.crcMCRF4XX
        packetData.append(crc as Data)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: packetData as Data)
        }
    }
    
    public func getRateOfIncreaseAlertLevel() {
        let getRateOfIncreaseAlertLevelData = Data(bytes: [0x17, 0x00, 0x21, 0x28] as [UInt8], count: 4)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: getRateOfIncreaseAlertLevelData)
        }
    }
    
    public func resetDeviceSpecificAlert() {
        let resetDeviceSpecificAlertData = Data(bytes: [0x19, 0x00, 0x31, 0xB2] as [UInt8], count: 4)
        
        if let characteristic = peripheral?.findCharacteristicByUUID(CGMSOCPCharacteristic) {
            self.writeCharacteristic(characteristic: characteristic, data: resetDeviceSpecificAlertData)
        }
    }
}

extension ContinuousGlucose: BluetoothProtocol {
    public func scanForGlucoseMeters() {
        Bluetooth.sharedInstance().startScanning(self.allowDuplicates)
        
        if(self.allowedToScanForPeripherals) {
            Bluetooth.sharedInstance().startScanning(self.allowDuplicates)
        }
    }
    
    public func bluetoothIsAvailable() {
        self.allowedToScanForPeripherals = true
        
        if let peripheral = self.peripheral {
            Bluetooth.sharedInstance().connectPeripheral(peripheral)
        } else {
            Bluetooth.sharedInstance().startScanning(self.allowDuplicates)
        }
    }
    
    public func bluetoothIsUnavailable() {
        
    }
    
    public func bluetoothError(_ error:Error?) {
        
    }
}

extension ContinuousGlucose: BluetoothPeripheralProtocol {
    public func didDiscoverPeripheral(_ peripheral:CBPeripheral) {
        self.peripheral = peripheral
        if (self.peripheralNameToConnectTo != nil) {
            if (peripheral.name == self.peripheralNameToConnectTo) {
                Bluetooth.sharedInstance().connectPeripheral(peripheral)
            }
        } else {
            continuousGlucoseMeterDiscoveryDelegate?.continuousGlucoseMeterDiscovered(continuousGlucoseMeter: peripheral)
        }
    }
    
    public func didConnectPeripheral(_ cbPeripheral:CBPeripheral) {
        self.peripheral = cbPeripheral
        continuousGlucoseDelegate?.continuousGlucoseMeterConnected(meter: cbPeripheral)
        
        Bluetooth.sharedInstance().discoverAllServices(cbPeripheral)
    }
    
    public func didDisconnectPeripheral(_ cbPeripheral: CBPeripheral) {
        self.peripheral = nil
        continuousGlucoseDelegate?.continuousGlucoseMeterDisconnected(meter: cbPeripheral)
    }
}

extension ContinuousGlucose: BluetoothServiceProtocol {
    public func didDiscoverServices(_ services: [CBService]) {
        print("Glucose#didDiscoverServices - \(services)")
    }
    
    public func didDiscoverServiceWithCharacteristics(_ service:CBService) {
        print("didDiscoverServiceWithCharacteristics - \(service.uuid.uuidString)")
        servicesAndCharacteristics[service.uuid.uuidString] = service.characteristics
        
        for characteristic in service.characteristics! {
            if characteristic.properties.contains(CBCharacteristicProperties.read) {
                DispatchQueue.global(qos: .background).async {
                    self.peripheral?.readValue(for: characteristic)
                }
            }
        }
    }
}

extension ContinuousGlucose: BluetoothCharacteristicProtocol {
    public func didUpdateValueForCharacteristic(_ cbPeripheral: CBPeripheral, characteristic: CBCharacteristic) {
        print("ContinuousGlucose#didUpdateValueForCharacteristic characteristic: \(characteristic.uuid.uuidString) value: \(String(describing: characteristic.value))")
    
        if(characteristic.uuid.uuidString == CGMFeatureCharacteristic) {
            if(crcIsValid(data: characteristic.value! as NSData)) {
                self.parseFeaturesResponse(data: characteristic.value! as NSData)
            }
        }
        if(characteristic.uuid.uuidString == CGMStatusCharacteristic) {
            if(crcIsValid(data: characteristic.value! as NSData)) {
                self.parseCGMStatus(data: characteristic.value! as NSData)
            }
        }
        if(characteristic.uuid.uuidString == CGMSessionRunTimeCharacteristic) {
            if(crcIsValid(data: characteristic.value! as NSData)) {
                self.parseCGMSessionRunTime(data: characteristic.value! as NSData)
            }
        }
        if(characteristic.uuid.uuidString == CGMSessionStartTimeCharacteristic) {
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when) {
                    DispatchQueue.once(executeToken: "continuousGlucose.readStartTime") {
                        Bluetooth.sharedInstance().readCharacteristic((self.peripheral?.findCharacteristicByUUID(CGMSessionStartTimeCharacteristic))!)
                    }
            }
            
            if(crcIsValid(data: characteristic.value! as NSData)) {
                self.parseCGMSessionStartTime(data: characteristic.value! as NSData)
            }
        }
        if(characteristic.uuid.uuidString == CGMSOCPCharacteristic) {
            if(crcIsValid(data: characteristic.value! as NSData)) {
                self.parseCGMSOCP(data: characteristic.value! as NSData)
            }
        }
        if(characteristic.uuid.uuidString == recordAccessControlPointCharacteristic) {
            if(crcIsValid(data: characteristic.value! as NSData)) {
                self.parseRACPReponse(data: characteristic.value! as NSData)
            }
        }
        if(characteristic.uuid.uuidString == CGMMeasurementCharacteristic) {
            if(crcIsValid(data: characteristic.value! as NSData)) {
                self.parseGlucoseMeasurement(data: characteristic.value! as NSData)
            }
        }
        if (characteristic.uuid.uuidString == "2A19") {
            batteryProfileSupported = true
        }
        if (characteristic.uuid.uuidString == "2A29") {
            self.manufacturerName = String(data: characteristic.value!, encoding: .utf8)
        }
        if (characteristic.uuid.uuidString == "2A24") {
            self.modelNumber = String(data: characteristic.value!, encoding: .utf8)
        }
        if (characteristic.uuid.uuidString == "2A25") {
            self.serialNumber = String(data: characteristic.value!, encoding: .utf8)
        }
        if (characteristic.uuid.uuidString == "2A26") {
            self.firmwareVersion = String(data: characteristic.value!, encoding: .utf8)
        }
        if (characteristic.uuid.uuidString == "2A27") {
            self.hardwareVersion = String(data: characteristic.value!, encoding: .utf8)
        }
        if (characteristic.uuid.uuidString == "2A28") {
            self.softwareVersion = String(data: characteristic.value!, encoding: .utf8)
        }
    }
    
    public func didUpdateNotificationStateFor(_ characteristic:CBCharacteristic) {
        if(characteristic.uuid.uuidString == recordAccessControlPointCharacteristic) {
            readNumberOfRecords()
        }
        if(characteristic.uuid.uuidString == CGMSOCPCharacteristic) {
            ContinuousGlucose.sharedInstance().resetDeviceSpecificAlert()
            ContinuousGlucose.sharedInstance().getCommunicationInterval()
            ContinuousGlucose.sharedInstance().getPatientHighAlertLevel()
            ContinuousGlucose.sharedInstance().getPatientLowAlertLevel()
            ContinuousGlucose.sharedInstance().getHypoAlertLevel()
            ContinuousGlucose.sharedInstance().getHyperAlertLevel()
            ContinuousGlucose.sharedInstance().getRateOfDecreaseAlertLevel()
            ContinuousGlucose.sharedInstance().getRateOfIncreaseAlertLevel()
            ContinuousGlucose.sharedInstance().getGlucoseCalibrationValue()
        }
    }
    
    public func didWriteValueForCharacteristic(_ cbPeripheral: CBPeripheral, didWriteValueFor descriptor:CBDescriptor) {
        
    }
}
