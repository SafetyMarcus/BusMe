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
    var apiKey = "?apikey=7x5GCf5SOBXLCt16Z6wd"
    var urlHeader = "http://api.translink.ca/rttiapi/v1/buses"
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
        var url = NSURL(string: "\(urlHeader)\(apiKey)&lat=\(userLocation.coordinate.latitude)&long=\(userLocation.coordinate.longitude)")
        var request = NSMutableURLRequest(URL: url!)
        request.setValue("application/JSON", forHTTPHeaderField: "Content-Type")
        request.setValue("application/JSON", forHTTPHeaderField: "accept")
        
        var annotation = MKPointAnnotation()
        annotation.title = "Pretend Annotation"
        annotation.subtitle = "pretending to be an annotation"
        annotation.coordinate = userLocation.coordinate
        
        mapView.addAnnotation(annotation)
//        var connection = NSURLConnection(request: request, delegate: self, startImmediately: true)
//        connection?.start()
    }
      
    func connection(connection: NSURLConnection, didReceiveData data: NSData)
    {
        self.data.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection)
    {
        var error = NSErrorPointer()
        var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(self.data, options: NSJSONReadingOptions.MutableContainers, error: error) as! NSDictionary
        
        NSString(data: data, encoding: NSUTF8StringEncoding)
        println(jsonResult)
    }
}