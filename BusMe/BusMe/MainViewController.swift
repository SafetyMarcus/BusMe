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
    var stops = NSMutableDictionary()

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
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT as Int
        let flag = 0 as UInt

        if let path = NSBundle.mainBundle().pathForResource("stop_times", ofType: "txt")
        {
            var stopTimesText = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
            var stopsArray = stopTimesText?.componentsSeparatedByString("\r\n")
            
            for index in 1...stopsArray!.count - 2
            {
                if let value = stopsArray?[index]
                {
                    var stopArray = value.componentsSeparatedByString(",")
                    var day = stopArray[0]
                    var time = stopArray[1]
                    
                    var stopString = stopArray[4] as NSString
                    var stop = stopString.integerValue
                    
                    var stopId = stopArray[3]
                    
                    var existingIds: [String] = self.stops.allKeys as! [String]
                    
                    var stopsArray = [BusStop]()
                    
                    if contains(existingIds, stopId)
                    {
                        stopsArray = self.stops.objectForKey(stopId) as! [BusStop]
                    }
                    
                    stopsArray.append(BusStop(day: day, time: time, stopNo: stop))
                    self.stops.setObject(stopsArray, forKey: stopId)
                }
            }
        }
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
                    annotation.subtitle = getTimeToStopForId((stop["stop_id"] as! String))
                    
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
    
    func getTimeToStopForId(id: String) -> String
    {
        var stopTimes: [BusStop] = stops.objectForKey(id) as! [BusStop]
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitHour | .CalendarUnitMinute | NSCalendarUnit.CalendarUnitWeekday, fromDate: date)
        
        let hour = components.hour
        let minutes = components.minute
        let dayOfWeek = components.weekday
        
        var max = stopTimes.count - 1
        for index in 0...max
        {
            let stopTime: BusStop = stopTimes[index] as BusStop
            
            if(isCorrectDay(dayOfWeek, stopDay: stopTime.day))
            {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "HH:mm:ss"
                let stopCalendar = NSCalendar.currentCalendar()
                let stopDate = dateFormatter.dateFromString(stopTime.time) as NSDate?
                
                if(stopDate != nil)
                {
                    let stopComponents = stopCalendar.components(.CalendarUnitHour | .CalendarUnitMinute, fromDate: stopDate!)
                
                    let stopHour = stopComponents.hour
                    let stopMinute = stopComponents.minute
                
                    if(stopHour > hour)
                    {
                        var returnString = ""
                        var hoursLeft = stopHour - hour
                        
                        var minutesLeft = -1
                        
                        if(stopMinute > minutes)
                        {
                            minutesLeft = stopMinute - minutes
                        }
                        else
                        {
                            hoursLeft -= 1
                            minutesLeft = 60 - minutes
                        }
                    
                        if(hoursLeft > 0)
                        {
                            returnString = "\(hoursLeft) hours and "
                        }
                    
                        returnString = "\(returnString)\(minutesLeft) minutes till arrival"
                    
                        return returnString
                    }
                }
            }
        }
        
        return "No more buses for today"
    }
    
    func isCorrectDay(day: Int, stopDay: NSString) -> Bool
    {
        if(day == 1 || day == 7)
        {
            var sunday = day == 1
            var stopSunday = stopDay.containsString("Sunday")
            var stopSaturday = stopDay.containsString("Saturday")
            
            if(sunday && stopSunday)
            {
                return true
            }
            else if(!sunday && stopSaturday)
            {
                return true
            }
            else
            {
                return false
            }
        }
        else
        {
            var stopWeekday = stopDay.containsString("Weekday")
            
            if(stopWeekday)
            {
                return true
            }
            else
            {
                return false
            }
        }
    }
}