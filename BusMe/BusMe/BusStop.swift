//
//  BusStop.swift
//  BusMe
//
//  Created by Marcus on 27/06/2015.
//  Copyright (c) 2015 easygoingapps. All rights reserved.
//

import Foundation
import CoreData

class BusStop
{
    var id = ""
    var day = NSString()
    var time = ""
    var stopNo = -1
    
    init(id:String, day: NSString, time: String, stopNo: NSInteger)
    {
        self.id = id
        self.day = day
        self.time = time
        self.stopNo = stopNo
    }
    
    init(stopObject: NSManagedObject)
    {
        self.id = stopObject.valueForKey("id") as! String
        self.day = stopObject.valueForKey("day") as! String
        self.time = stopObject.valueForKey("time") as! String
        self.stopNo = stopObject.valueForKey("stop") as! Int
    }
    
    func save(context: NSManagedObjectContext)
    {
        var entityDesc = NSEntityDescription.entityForName("BusStopTime", inManagedObjectContext: context)
        var stop = NSManagedObject(entity: entityDesc!, insertIntoManagedObjectContext: context)
        
        stop.setValue(id, forKey: "id")
        stop.setValue(day, forKey: "day")
        stop.setValue(time, forKey: "time")
        stop.setValue(stopNo, forKey: "stop")
    }
}