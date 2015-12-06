//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Hyun on 2015. 12. 3..
//  Copyright © 2015년 wook2. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var overlayView: UIView!
    // The property uses a property observer. Any time its
    // value is set it canceles the previous NSURLSessionTask

    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
    

}
