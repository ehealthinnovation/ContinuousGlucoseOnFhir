//
//  DiscoverCGMViewController.swift
//  CCBluetooth
//
//  Created by Kevin Tallevi on 7/28/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

// swiftlint:disable syntactic_sugar

import Foundation
import UIKit
import CCBluetooth
import CCContinuousGlucose
import CoreBluetooth

class DiscoverCGMViewController: UITableViewController, ContinuousGlucoseMeterDiscoveryProtocol {
    private var continuousGlucose: ContinuousGlucose!
    let cellIdentifier = "CGMCellIdentifier"
    var discoveredContinuousGlucoseMeters: Array<CBPeripheral> = Array<CBPeripheral>()
    var storedContinuousGlucoseMeters: Array<CBPeripheral> = Array<CBPeripheral>()
    var peripheral: CBPeripheral!
    let refresh = UIRefreshControl()
    let browser = NetServiceBrowser()
    var fhirService = NetService()
    var fhirServiceIP: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DiscoverCGMViewController#viewDidLoad")
        
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl?.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        ContinuousGlucose.sharedInstance().continuousGlucoseMeterDiscoveryDelegate  = self
    }
    
    @objc func onRefresh() {
        refreshControl?.endRefreshing()
        discoveredContinuousGlucoseMeters.removeAll()
        self.refreshTable()
        continuousGlucose = ContinuousGlucose()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.refreshTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cgmvc =  segue.destination as! CGMViewController
        cgmvc.selectedMeter = self.peripheral
    }
    
    func continuousGlucoseMeterDiscovered(continuousGlucoseMeter: CBPeripheral) {
        print("DiscoverCGMViewController#glucoseMeterDiscovered")
        discoveredContinuousGlucoseMeters.append(continuousGlucoseMeter)
        print("cgm: \(String(describing: continuousGlucoseMeter.name))")
        
        self.refreshTable()
    }
    
    // MARK: Table data source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return discoveredContinuousGlucoseMeters.count
        } else {
            return storedContinuousGlucoseMeters.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        
        if indexPath.section == 0 {
            let peripheral = Array(self.discoveredContinuousGlucoseMeters)[indexPath.row]
            cell.textLabel!.text = peripheral.name
            cell.detailTextLabel!.text = peripheral.identifier.uuidString
        } else {
            let peripheral = Array(self.storedContinuousGlucoseMeters)[indexPath.row]
            cell.textLabel!.text = peripheral.name
            cell.detailTextLabel!.text = peripheral.identifier.uuidString
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Discovered CGM"
        } else {
            return "Previously Connected CGM"
        }
    }
    
    //MARK table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let glucoseMeter = Array(discoveredContinuousGlucoseMeters)[indexPath.row]
            self.peripheral = glucoseMeter
            self.addPreviouslySelectedGlucoseMeter(self.peripheral)
            self.didSelectDiscoveredGlucoseMeter(Array(self.discoveredContinuousGlucoseMeters)[indexPath.row])
        } else {
            let glucoseMeter = Array(storedContinuousGlucoseMeters)[indexPath.row]
            self.peripheral = glucoseMeter
            self.didSelectStoredGlucoseMeter(Array(self.storedContinuousGlucoseMeters)[indexPath.row])
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "segueToGlucoseMeter", sender: self)
    }
    
    func didSelectDiscoveredGlucoseMeter(_ peripheral: CBPeripheral) {
        print("DiscoverCGMViewController#didSelectDiscoveredGlucoseMeter \(String(describing: peripheral.name))")
        Bluetooth.sharedInstance().connectPeripheral(peripheral)
    }
    
    func didSelectStoredGlucoseMeter(_ peripheral: CBPeripheral) {
        print("DiscoverCGMViewController#didSelectStoredGlucoseMeter \(String(describing: peripheral.name))")
        Bluetooth.sharedInstance().reconnectPeripheral(peripheral.identifier.uuidString)
    }
    
    func addPreviouslySelectedGlucoseMeter(_ cbPeripheral: CBPeripheral) {
        var peripheralAlreadyExists: Bool = false
        
        for aPeripheral in self.storedContinuousGlucoseMeters {
            if aPeripheral.identifier.uuidString == cbPeripheral.identifier.uuidString {
                peripheralAlreadyExists = true
            }
        }
        
        if !peripheralAlreadyExists {
            self.storedContinuousGlucoseMeters.append(cbPeripheral)
        }
    }

    func refreshTable() {
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    func getIPV4StringfromAddress(address: [Data]) -> String {
        let data = address.first! as NSData
        var values: [Int] = [0, 0, 0, 0]
        for i in 0...3 {
            data.getBytes(&values[i], range: NSRange(location: i+4, length: 1))
        }
        let ipStr = String(format: "%d.%d.%d.%d", values[0], values[1], values[2], values[3])
        
        return ipStr
    }
    
    func showFHIRServerAlertController() {
        let alert = UIAlertController(title: "Select FHIR server", message: "", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "fhirtest.uhn.ca", style: .default) { action in
            action.isEnabled = true
            FHIR.fhirInstance.setFHIRServerAddress(address: "fhirtest.uhn.ca")
        })
        alert.addAction(UIAlertAction(title: self.fhirService.name, style: .default) { action in
            action.isEnabled = true
            FHIR.fhirInstance.setFHIRServerAddress(address: self.fhirServiceIP!)
        })
        
        self.present(alert, animated: true)
    }
    
    @IBAction func discoverFHIRServersButtonAction(_ sender: Any) {
        print("discoverFHIRServersButtonAction")
        self.browser.delegate = self
        self.browser.searchForServices(ofType: "_http._tcp.", inDomain: "local")
    }
}

extension DiscoverCGMViewController: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        if service.name.contains("fhir") {
            print("found fhir server")
            self.browser.stop()
            fhirService = service
            fhirService.delegate = self
            fhirService.resolve(withTimeout: 5.0)
        }
    }
}

extension DiscoverCGMViewController: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        fhirServiceIP = self.getIPV4StringfromAddress(address:sender.addresses!) + ":" + String(sender.port)
        
        self.showFHIRServerAlertController()
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("didNotResolve")
    }
    
    func netServiceWillResolve(_ sender: NetService) {
        print("netServiceWillResolve")
    }
}
