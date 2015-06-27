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

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate
{
    @IBOutlet var mapView: MKMapView!
    
    var manager: CLLocationManager!

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
}