//
//  Pin.swift
//  VirtualTourist
//
//  Created by Hyun on 2015. 11. 30..
//  Copyright © 2015년 wook2. All rights reserved.
//

import Foundation
import CoreData

class Pin : NSManagedObject {
    
    struct Keys {
        
        static let Latitude = "latitude"
        static let Longitude = "longitude"
     //   static let ZoomLevel = "zoom_level"
        
    }
    
    @NSManaged var latitude : NSNumber
    @NSManaged var longitude : NSNumber
    @NSManaged var pictures: [Picture]
    // @NSManaged var zoomLevel : Int
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary : [String:AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        print(dictionary)
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
        //zoomLevel = dictionary[Keys.ZoomLevel] as! Int
    }
    
}