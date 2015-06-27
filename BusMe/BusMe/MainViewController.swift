//
//  MainViewController.swift
//  BusMe
//
//  Created by Marcus on 27/06/2015.
//  Copyright (c) 2015 easygoingapps. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, NSURLConnectionDataDelegate
{
    @IBOutlet var mapView: MKMapView!
    
    var manager: CLLocationManager!
    var data = NSMutableData()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        self.mapView.setUserTrackingMode(.Follow, animated: true)

        
        self.manager = CLLocationManager()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.requestAlwaysAuthorization()
        self.manager.startUpdatingLocation()
    }
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!)
    {
        var url = NSURL(string: "https://data.qld.gov.au/api/action/datastore_search?resource_id=9efd08f6-3a71-4004-8422-32a2fa8d91ef")
        var request = NSMutableURLRequest(URL: url!)
        
        var connection = NSURLConnection(request: request, delegate: self, startImmediately: true)
        connection?.start()
    }
      
    func connection(connection: NSURLConnection, didReceiveData data: NSData)
    {
        self.data.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection)
    {
        var error = NSErrorPointer()
        var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(self.data, options: NSJSONReadingOptions.MutableContainers, error: error) as! NSDictionary
        
        if let result: NSDictionary = jsonResult["result"] as? NSDictionary
        {
            if let records: NSArray = result["records"] as? NSArray
            {
                for index in 0...records.count - 1
                {
                    var annotation = MKPointAnnotation()
                    
                    var stop: NSDictionary = records[index] as! NSDictionary
                    annotation.title = stop["stop_name"] as! String
                    annotation.subtitle = "Bus Stop"
                    
                    var latString: NSString = stop["stop_lat"] as! NSString
                    var longString: NSString = stop["stop_lon"] as! NSString
                    
                    var lat = latString.doubleValue
                    var long = longString.doubleValue
                    annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    
                    self.mapView.addAnnotation(annotation)
                }
            }
        }
    }
}