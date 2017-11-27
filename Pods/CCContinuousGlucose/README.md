# CCContinuousGlucose

[![CI Status](http://img.shields.io/travis/ktallevi/CCContinuousGlucose.svg?style=flat)](https://travis-ci.org/ktallevi/CCContinuousGlucose)
[![Version](https://img.shields.io/cocoapods/v/CCContinuousGlucose.svg?style=flat)](http://cocoapods.org/pods/CCContinuousGlucose)
[![License](https://img.shields.io/cocoapods/l/CCContinuousGlucose.svg?style=flat)](http://cocoapods.org/pods/CCContinuousGlucose)
[![Platform](https://img.shields.io/cocoapods/p/CCContinuousGlucose.svg?style=flat)](http://cocoapods.org/pods/CCContinuousGlucose)

CCContinuousGlucose is an iOS library designed to collect data from a continuous glucose monitor. Data communication complies with the Bluetooth SIG approved CGM Profile/Service specification.

A sample application is included to show usage of the library, which consists of cgm sensor configuration, data collection, and optionally upload data to a FHIR (DSTU3) server.


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

CCContinuousGlucose is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "CCContinuousGlucose"
```

## Usage
##### Connecting to the CGM Sensor
CCContinuousGlucose has been tested against the cgm simulator which is available at https://github.com/uhnmdi/BLECgmSim

The simulator will appear as "CGM Simulator", tap the discovered device to connect to it. The pin code for pairing is 19655

##### Configuring the CGM Sensor
The sample application includes a method that demonstrates usage of the methods available to configure the cgm sensor.

```
public func prepareSession() {
  resetDeviceSpecificAlert()
  setSessionStartTime()
  setCommunicationInterval(minutes: 1)
  setGlucoseCalibrationValue(glucoseConcentration: 120,
   calibrationTime: 10, type: 1, location: 1)
  setPatientHighAlertLevel(level: 280)
  setPatientLowAlertLevel(level: 100)
  setHyperAlertLevel(level: 300)
  setHypoAlertLevel(level: 90)
  setRateOfDecreaseAlertLevel(glucoseConcentration: -1.0)
  setRateOfIncreaseAlertLevel(glucoseConcentration: 1.0)
  getSessionStartTime()
}
```

##### Graphing the CGM data
Tapping 'start session' will call the prepareSession() method mentioned earlier to configure the sensor, and then start the session. Data received from the simulator will be graphed on screen. Individual data points can be selected to display the raw packet, along with the parsed data. Note that the graph supports pinching to zoom in and out, along with single finger scrolling. The x-axis indicates time in units of minutes, and the y-axis indicates glucose concentration level. Tap the back button to stop the session.

##### FHIR integration
Data can be uploaded to either the UHN 'fhirtest' server, or a FHIR server running on the same network as the iOS device. On the initial screen, tap "Select FHIR Server", and select from the list of discovered FHIR servers.

To run your own FHIR server, download hapi-fhir-cli from http://hapifhir.io/doc_cli.html. Extract the archive and run the server from a terminal window using the command 'hapi-fhir-cli run-server'

The FHIR server must advertise itself on the network to be discovered by the sample application. From a terminal window run the following command 'dns-sd -R "fhir" _http._tcp . 8080'


## Author

ktallevi, ktallevi@ehealthinnovation.org

## License

CCContinuousGlucose is available under the MIT license. See the LICENSE file for more info.
