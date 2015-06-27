//
//  BusStopAnnotation.swift
//  BusMe
//
//  Created by Marcus on 28/06/2015.
//  Copyright (c) 2015 easygoingapps. All rights reserved.
//

import Foundation
import MapKit

class BusStopAnnotation: NSObject, MKAnnotation
{
    var id: String
    var title: String
    var subtitle: String
    var coordinate: CLLocationCoordinate2D
    
    override init()
    {
        self.id = ""
        self.title = ""
        self.subtitle = ""
        self.coordinate = CLLocationCoordinate2D()
    }
    
    init(coordinates: CLLocationCoordinate2D)
    {
        self.id = ""
        self.title = ""
        self.subtitle = ""
        self.coordinate = coordinates
    }
}