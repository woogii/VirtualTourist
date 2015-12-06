//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Hyun on 2015. 11. 29..
//  Copyright © 2015년 wook2. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate {

    let identifier = "PhotoCell"
    let regionRadius: CLLocationDistance = 3000

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var miniMapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    var pin: Pin!
    var longitude:Double!
    var latitude : Double!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells. You can see how the array
    // works by searching through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // MARK : - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(center,
            regionRadius * 2.0, regionRadius * 2.0)
    
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        
        dispatch_async(dispatch_get_main_queue(), {
            self.miniMapView.setRegion(coordinateRegion, animated: false)
            self.miniMapView.addAnnotation(annotation)
        })

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width, 
        // with no space in between 
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        bottomButton.enabled = false

        if pin.pictures.isEmpty {
        
            let methodArguments:[String:String!] = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "bbox" :  createBoundingBoxString(longitude, latitude: latitude),
                "safe_search" : SAFE_SEARCH,
                "extras": EXTRAS,
                "per_page": PER_PAGE,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK
            ]

            FlickrClient.sharedInstance().taskForResource(methodArguments) { JSONResult, error in
            
                if let error = error {
                    self.alertViewForError(error)
                } else {
                    
                    if let photoDictionary = JSONResult["photos"] as? NSDictionary {
                    
                        if let photoArray = photoDictionary["photo"] as? [[String:AnyObject]] {
                            print("photoArray: \(photoArray.count)")
                            
                            //let photoDictionary = photoArray[randomPage] as [String:AnyObject]
                            //let photo = photoArray[randomPage] as [String:AnyObject]
                            
                            let _ = photoArray.map() { (dictionary:[String:AnyObject])->Picture in
                                
                                let picture = Picture(dictionary:dictionary, context: self.sharedContext)
                                picture.pin = self.pin
                                return picture
                            }
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.collectionView.reloadData()
                                self.bottomButton.enabled = true
                            }
                            
                            CoreDataStackManager.sharedInstance().saveContext()
                            
                        }
                    }
                }
            }
            
        } else  {
            // if a pin already has pictures in coredata 
            bottomButton.enabled = true 
        }

    }

    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    
    func createBoundingBoxString(longitude:Double, latitude:Double)->String {
        
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_WIDTH, LON_MAX)
        
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }

    
    func alertViewForError(error:NSError) {
        let alertView = UIAlertController(title: "", message: "\(error.localizedDescription)" , preferredStyle: .Alert)
        alertView.addAction(UIAlertAction(title: "Dismiss", style:.Default, handler: nil))
        presentViewController(alertView, animated: true, completion: nil)
    }
    
    
    // MARK: - Delegate Methods
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.pictures.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! PhotoCell
        var cellImage = UIImage(named: "placeholder")

        cell.imageView!.image = nil
        cell.overlayView.hidden = true
        cell.activityIndicator.startAnimating()
        
        let pic = pin.pictures[indexPath.row]
        
        if pic.urlString.characters.count == 0 || pic.urlString == "" {
            cellImage = UIImage(named: "noImage")
            cell.activityIndicator.stopAnimating()
        } else {
            
            let task = FlickrClient.sharedInstance().taskForImage(pic.urlString) { data, error in
                
                if let data = data {
                    
                    let image = UIImage(data:data)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView!.image = image
                        cell.activityIndicator.stopAnimating()
                    }
                }
            }
            cell.taskToCancelifCellIsReused = task
        }
        
        cell.imageView!.image = cellImage
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        

        // The value of this property is a floating-point number in the range 0.0 to 1.0, where 0.0 represents totally transparent and 1.0 represents totally opaque. This value affects only the current view and does not affect any of its embedded subviews.
        if let index = selectedIndexes.indexOf(indexPath) {
            print(indexPath.row)
            print("index is already selected")
            selectedIndexes.removeAtIndex(index)
            cell.overlayView.hidden = true 
        } else {
            print(indexPath.row)
            print("index has not been selected")
            selectedIndexes.append(indexPath)
            cell.overlayView.hidden = false
            cell.overlayView.alpha = 0.5
        }
    
        updateBottomButton()
    }
    
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
        }
        else {
            pinView!.annotation = annotation
        }
        pinView?.animatesDrop = true
        return pinView
        
    }
    
    @IBAction func bottomBtnClicked(sender: AnyObject) {
        
        if selectedIndexes.isEmpty {
            deleteAllPictures()
        } else {
            deleteSelectedPictures()
        }
        
    }
    
    
    
    func deleteAllPictures() {
        //  delete All pictures
        for pic in pin.pictures {
            sharedContext.deleteObject(pic)
        }
        reloadPictures()
    }
    
    func deleteSelectedPictures() {
        print("delete selected pics")
        var picturesToDelete = [Picture]()
        
        for indexPath in selectedIndexes {
            picturesToDelete.append(pin.pictures[indexPath.row])
            let pic = pin.pictures[indexPath.row]
            pic.pin = nil
        }
        
        for pic in picturesToDelete {
            sharedContext.deleteObject(pic)
        }
        
        collectionView.deleteItemsAtIndexPaths(selectedIndexes)
        //self.collectionView?.reloadItemsAtIndexPaths(self.selectedIndexes)

//        collectionView?.performBatchUpdates({
//            // Reloads just the items at the specified index paths
//            
//            dispatch_async(dispatch_get_main_queue()){
//            self.collectionView?.reloadItemsAtIndexPaths(self.selectedIndexes)
//            print("in perform batch update")
//            return
//            }
//            
//            }, completion: nil)
        
        selectedIndexes = [NSIndexPath]()
    }
    
    func reloadPictures() {
        
        let per_page = Int(PER_PAGE)!
        
        // A value of a page variable is estimated based on the facts that Flick return at most 4,000 images given any search query, and we set per_page parameter '21'.
        // This value means a possibel maximum number of pages that we have.
        
        let page = Int(TOTAL_PAGE/per_page)
        let randomPage = Int(arc4random_uniform(UInt32(page))+1)
        print("randomPage:\(randomPage)")
        
        let methodArguments:[String:String!] = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox" :  createBoundingBoxString(longitude, latitude: latitude),
            "safe_search" : SAFE_SEARCH,
            "extras": EXTRAS,
            "per_page": PER_PAGE,
            "page" :  "\(randomPage)",
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        FlickrClient.sharedInstance().taskForResource(methodArguments) { JSONResult, error in
            
            if let error = error {
                self.alertViewForError(error)
            } else {
                
                if let photoDictionary = JSONResult["photos"] as? NSDictionary {
                    
                    
                    if let photoArray = photoDictionary["photo"] as? [[String:AnyObject]] {
                        print("photoArray: \(photoArray.count)")
                        
                        let _ = photoArray.map() { (dictionary:[String:AnyObject])->Picture in
                            
                            let picture = Picture(dictionary:dictionary, context: self.sharedContext)
                            picture.pin = self.pin
                            return picture
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.collectionView.reloadData()
                            self.bottomButton.enabled = true
                        }
                        
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                    }
                }
            }
        }

        
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0  {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }

}