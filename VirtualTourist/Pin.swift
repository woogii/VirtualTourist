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
    
    @NSManaged var latitude : Double
    @NSManaged var longitude : Double
    @NSManaged var zoomLevel : Int
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
    }
    
}