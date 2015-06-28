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
import CoreData

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, NSURLConnectionDataDelegate
{
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var bottomSheet: UIView!
    @IBOutlet weak var busStop: UILabel!
    @IBOutlet weak var busTime: UILabel!
    
    var manager: CLLocationManager!
    var data = NSMutableData()
    var stops = NSMutableDictionary()
    var titles = NSMutableDictionary()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        var appContext = UIApplication.sharedApplication().delegate as! AppDelegate
        
        self.mapView.setUserTrackingMode(.Follow, animated: true)
        self.busStop.text = "Select a bus stop to get started"
        self.busTime.text = ""
        
        self.manager = CLLocationManager()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.requestAlwaysAuthorization()
        self.manager.startUpdatingLocation()
        
        let fetchRequest = NSFetchRequest(entityName: "BusStopTime")
        
        let fetchResults = appContext.managedObjectContext?.executeFetchRequest(fetchRequest, error: nil)
        
        if(fetchResults == nil || fetchResults!.count == 0)
        {
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
                        
                        var busStop = BusStop(id: stopId, day: day, time: time, stopNo: stop)
                        
                        busStop.save(appContext.managedObjectContext!)
                        stopsArray.append(busStop)
                        self.stops.setObject(stopsArray, forKey: stopId)
                    }
                }
                
                appContext.saveContext()
            }
        }
        else
        {
            if let results = fetchResults
            {
                for index in 0...results.count - 1
                {
                    let busStop: NSManagedObject = results[index] as! NSManagedObject
                    var stop = BusStop(stopObject: busStop)
                
                    var stopsArray = [BusStop]()
                    var existingIds = stops.allKeys as! [String]
                    if contains(existingIds, stop.id)
                    {
                        stopsArray = stops.objectForKey(stop.id) as! [BusStop]
                    }
                
                    stopsArray.append(stop)
                    self.stops.setObject(stopsArray, forKey: stop.id)
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool)
    {
        self.bottomSheet.layer.cornerRadius = 2.0
        
        self.bottomSheet.layer.shadowColor = UIColor.blackColor().CGColor
        self.bottomSheet.layer.shadowOpacity = 0.2
        self.bottomSheet.layer.shadowRadius = 1.0
        self.bottomSheet.layer.shadowOpacity = 0.2
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
                    var annotation = BusStopAnnotation()
                    
                    var stop: NSDictionary = records[index] as! NSDictionary
                    annotation.title = stop["stop_name"] as! String
                    
                    var id: String = stop["stop_id"] as! String
                    annotation.id = id
                    annotation.subtitle = getTimeToStopForId(id)
                    titles.setValue(annotation.title, forKey: id)
                    
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
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
    {
        if(annotation.isKindOfClass(MKUserLocation))
        {
            return nil
        }
        
        var annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "BusStop")
        
        var customAnnotation = annotation as! BusStopAnnotation
        customAnnotation.title = titles.objectForKey(customAnnotation.id) as! String
        customAnnotation.subtitle = getTimeToStopForId(customAnnotation.id)
        
        annotationView.annotation = customAnnotation
        annotationView.image = UIImage(named: "map_icon")
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!)
    {
        if let stopAnnotation = view.annotation as? BusStopAnnotation
        {
            UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseOut, animations: { () -> Void in
                self.bottomSheet.center.y += self.bottomSheet.frame.height
                }, completion: { (Bool) -> Void in
                    self.animateSheetIn(view.annotation)
            })
        }
    }
    
    func animateSheetIn(stopAnnotation: MKAnnotation)
    {
        self.busStop.text = stopAnnotation.title
        self.busTime.text = stopAnnotation.subtitle
        
        UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseOut, animations: { () -> Void in
            self.bottomSheet.center.y -= self.bottomSheet.frame.height
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func getTimeToStopForId(id: String) -> String
    {
        var returnString = ""
        var stopTimes: [BusStop] = stops.objectForKey(id) as! [BusStop]
        var currentHoursLeft = -1
        var currentMinutesLeft = -1
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitHour | .CalendarUnitMinute | NSCalendarUnit.CalendarUnitWeekday, fromDate: date)
        
        let hour = components.hour
        let minutes = components.minute
        let dayOfWeek = components.weekday
        
        var max = stopTimes.count - 1
        for index in stride(from: max, through: 0, by: -1)
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
                
                    if(stopHour > hour || (stopHour == hour && stopMinute > minutes))
                    {
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
                    
                        if(currentHoursLeft == -1 || hoursLeft < currentHoursLeft || (hoursLeft == currentHoursLeft && minutesLeft < currentMinutesLeft))
                        {
                            returnString = ""
                            currentHoursLeft = hoursLeft
                            currentMinutesLeft = minutesLeft
                            
                            if(hoursLeft > 0)
                            {
                                returnString = "\(hoursLeft) hours and "
                            }
                            returnString = "\(returnString)\(minutesLeft) minutes till arrival"
                        }
                    }
                }
            }
        }
        
        if(currentHoursLeft != -1)
        {
            return returnString
        }
        else
        {
            return "No more buses for today"
        }
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