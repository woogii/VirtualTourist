//
//  Picture.swift
//  VirtualTourist
//
//  Created by Hyun on 2015. 12. 3..
//  Copyright © 2015년 wook2. All rights reserved.
//

import Foundation
import UIKit 

struct  Picture {
    
    var urlString:String
    
    init(dictionary : [String:AnyObject]) {
    
        print(dictionary)
        urlString = dictionary["url_m"] as! String
        
        //zoomLevel = dictionary[Keys.ZoomLevel] as! Int
    }

}


    