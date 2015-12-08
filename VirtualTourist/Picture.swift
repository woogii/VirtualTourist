//
//  Picture.swift
//  VirtualTourist
//
//  Created by Hyun on 2015. 12. 3..
//  Copyright © 2015년 wook2. All rights reserved.
//

import UIKit
import CoreData

class Picture : NSManagedObject {

    struct Keys {
        static let imagePath = "url_m"
    }

    //@NSManaged var urlString: String
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary : [String:AnyObject], context : NSManagedObjectContext) {
    
        let entity = NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        super.init(entity:entity, insertIntoManagedObjectContext: context)
                
        //urlString = dictionary[Keys.UrlString] as! String
        imagePath = dictionary[Keys.imagePath] as? String
    }
    
    var pinnedImage: UIImage? {
        
        get {
            let url = NSURL(fileURLWithPath: imagePath!)
            let fileName = url.lastPathComponent
            return FlickrClient.Caches.imageCache.imageWithIdentifier(fileName!)
            // return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            let url = NSURL(fileURLWithPath: imagePath!)
            let fileName = url.lastPathComponent
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: fileName!)
            //FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!)
        }
    }


}


    