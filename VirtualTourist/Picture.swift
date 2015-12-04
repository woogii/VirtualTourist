//
//  Picture.swift
//  VirtualTourist
//
//  Created by Hyun on 2015. 12. 3..
//  Copyright © 2015년 wook2. All rights reserved.
//

import Foundation
import CoreData

class Picture : NSManagedObject {
    
    // var urlString:String
    
    @NSManaged var urlString: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary : [String:AnyObject], context : NSManagedObjectContext) {
    
        let entity = NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        super.init(entity:entity, insertIntoManagedObjectContext: context)
            
        //print(dictionary)
        urlString = dictionary["url_m"] as! String
    }

}


    