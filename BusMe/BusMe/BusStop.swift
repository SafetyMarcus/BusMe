//
//  BusStop.swift
//  BusMe
//
//  Created by Marcus on 27/06/2015.
//  Copyright (c) 2015 easygoingapps. All rights reserved.
//

import Foundation

class BusStop
{
    var day = ""
    var time = ""
    var stopNo = -1
    
    init(day: String, time: String, stopNo: NSInteger)
    {
        self.day = day
        self.time = time
        self.stopNo = stopNo
    }
}