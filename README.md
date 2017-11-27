# ContinuousGlucoseOnFhir

This application demonstrates acquiring data from a Continuous Glucose Profile-compliant sensor, and uploading all necessary resources to a FHIR server.

##### Swiftlint
ContinuousGlucoseOnFHIR uses swiftlint during the build process. From a terminal, run 'brew install swiftlint'. Install swiftlint to ensure the project builds without any warnings.

##### Uploading records to a FHIR server
Records can be uploaded to a FHIR server from within the ContinuousGlucoseOnFHIR application. Selecting a FHIR server from the main screen, and then starting a session will automatically begin uploading records as they are received from the CGM sensor.

##### Discovery of local FHIR server

Data can be uploaded to either the UHN 'fhirtest' server, or a FHIR server running on the same network as the iOS device. On the initial screen, tap "Select FHIR Server", and select from the list of discovered FHIR servers.

To run your own FHIR server, download hapi-fhir-cli from http://hapifhir.io/doc_cli.html. Extract the archive and run the server from a terminal window using the command 'hapi-fhir-cli run-server'

The FHIR server must advertise itself on the network to be discovered by the sample application. From a terminal window run the following command 'dns-sd -R "fhir" _http._tcp . 8080'
