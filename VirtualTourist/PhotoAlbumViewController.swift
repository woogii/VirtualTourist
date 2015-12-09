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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate, NSFetchedResultsControllerDelegate{

    // MARK : - Properties
    
    let identifier = "PhotoCell"
    let regionRadius: CLLocationDistance = 3000

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var miniMapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var messageLabel: UILabel!
    
    var pin: Pin!
    var longitude:Double!
    var latitude : Double!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells. 
    var selectedIndexes = [NSIndexPath]()
    
    // These variables are declared to keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    
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
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}

        fetchedResultsController.delegate = self
        
        messageLabel.hidden = true
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

            fetchImages(methodArguments)
            
        } else  {
            // if a pin already has pictures in CoreData 
            bottomButton.enabled = true 
        }

    }

    // MARK : - Fetch Images
    
    func fetchImages(methodArguments:[String:String!]) {
    
        
        FlickrClient.sharedInstance().taskForResource(methodArguments) { JSONResult, error in
            
            if let error = error {
                self.alertViewForError(error)
            } else {
                
                if let photoDictionary = JSONResult["photos"] as? NSDictionary {
                    
                    if let photoArray = photoDictionary["photo"] as? [[String:AnyObject]] {
                        
                        if ( photoArray.count > 0 ) {
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                
                                let _ = photoArray.map() { (dictionary:[String:AnyObject])->Picture in
                                    
                                    let picture = Picture(dictionary:dictionary, context: self.sharedContext)
                                    picture.pin = self.pin
                                    return picture
                                }
                                
                                self.bottomButton.enabled = true
                            }
                        } else {
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.messageLabel.hidden = false
                                self.collectionView.backgroundColor = UIColor.whiteColor()
                                self.messageLabel.text = "This pin has no image"
                                self.bottomButton.enabled = true
                            }
                            
                        }
                    }
                }
            }
        }

    }
    
    // MARK : - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        
        // Fetch requests contain at least one sort descriptor to order the results
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
    
        // NSFetchedResultsController uses the key path to split the results into sections. Passing 'nil' indicates that the controller should generate a 
        // single section. Using a cache can avoid the overhead of computing the section and index information. Passing 'nil' in cacheName prevents caching.
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultController
    }()
    
    // MARK : - Fetched Results Controller Delegate 
    
    // Whenever changes are made to Core Data the following three methods are invoked. The first method is used to create three fresh arrays to record 
    // the index paths that will be changed.
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    // This method gets invoked multiple times, once for each Picture object that is added, deleted, or changed.
    func controller(controller :NSFetchedResultsController, didChangeObject anObject:AnyObject, atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
            
            switch type {
                
            case .Insert:
                // A new Picture Object has been added to Core Data. We remember its index path so that we can add a cell in 'controllerDidChangeContent'
                insertedIndexPaths.append(newIndexPath!)
                break
            case .Delete:
                // A Picture object has been deleted from Core Data. We keep remember its index path so that we can remove the correspoding cell in 'controllerDidChangeContent'
                deletedIndexPaths.append(indexPath!)
                break
            case .Update:
                // Core Data would notify us of changes if any occured
                updatedIndexPaths.append(indexPath!)
                break
            default:
                break
            }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected into the three index path arrays (insert, delete, and update)
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        
        // All of the changes are performed inside a closure that is handed to the collection view
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
        }, completion: nil)
    }
    
    
    // MARK : - Building a Parameter
    
    func createBoundingBoxString(longitude:Double, latitude:Double)->String {
        
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_WIDTH, LON_MAX)
        
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }

    
    // MARK : - Display an Error
    
    func alertViewForError(error:NSError) {
        let alertView = UIAlertController(title: "", message: "\(error.localizedDescription)" , preferredStyle: .Alert)
        alertView.addAction(UIAlertAction(title: "Dismiss", style:.Default, handler: nil))
        presentViewController(alertView, animated: true, completion: nil)
    }
    
    
    // MARK: - Delegate Methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // return pin.pictures.count
        let sectionInfo  = self.fetchedResultsController.sections![section] 
        
        // print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! PhotoCell
    
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
            cell.overlayView.hidden = true 
        } else {
            print(indexPath.row)
            selectedIndexes.append(indexPath)
            cell.overlayView.hidden = false
            // The value of this property is a floating-point number in the range 0.0 to 1.0, where 0.0 represents totally transparent and 1.0 represents totally opaque. This value affects only the current view and does not affect any of its embedded subviews.
            cell.overlayView.alpha = 0.5
        }
    
        updateBottomButton()
    }
    
    // MARK : - Configure Cell 
    
    func configureCell(cell: PhotoCell , atIndexPath indexPath : NSIndexPath) {
        
        let pic = fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        
        var pinnedImage = UIImage(named: "placeholder")
        
        cell.imageView!.image = nil
        cell.overlayView.hidden = true
        cell.activityIndicator.startAnimating()
        
        
        if pic.imagePath == nil || pic.imagePath == "" {
            print("no image path")
            pinnedImage = UIImage(named: "noImage")
            cell.activityIndicator.stopAnimating()
            
        } else if  pic.pinnedImage != nil {
            print("images exist")
            pinnedImage = pic.pinnedImage
            cell.activityIndicator.stopAnimating()
        }
        else {
            print("paths exists but no images")
            let task = FlickrClient.sharedInstance().taskForImage(pic.imagePath!) { data, error in
                
                if let error = error {
                    print("Poster download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    
                    let image = UIImage(data:data)
                    
                    // The below line is moved inside of dispatch_async for thread-safe operation
                    // pic.pinnedImage = image
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        // update the model, so that the information gets cashed
                        pic.pinnedImage = image

                        cell.imageView!.image = image
                        cell.activityIndicator.stopAnimating()
                    }
                }
            }
            cell.taskToCancelifCellIsReused = task
        }
        
        cell.imageView!.image = pinnedImage
    }
    
    // MARK: - MKMapViewDelegate function

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
    
    // MARK: - Action 
    
    @IBAction func bottomBtnClicked(sender: AnyObject) {
        
        if selectedIndexes.isEmpty {
            deleteAllPictures()
        } else {
            deleteSelectedPictures()
        }
        
    }

    // MARK: - Delete Pictures 
    
    func deleteAllPictures() {
        for pic in fetchedResultsController.fetchedObjects as! [Picture] {
            sharedContext.deleteObject(pic)
            
            // delete the underlying photos
            pic.pinnedImage = nil
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        reloadPictures()
    }
    
    func deleteSelectedPictures() {
 
        var picturesToDelete = [Picture]()
  
        for indexPath in selectedIndexes {
            picturesToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Picture)
        }
        
        for pic in picturesToDelete {
            sharedContext.deleteObject(pic)
            
            // delete the underlying photos
            pic.pinnedImage = nil
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        selectedIndexes = [NSIndexPath]()
        updateBottomButton()
    }
 
    // MARK : - Reload Pictures
    
    // Reload pictures from Flickr only if all pictures are deleted
    func reloadPictures() {
        
        let per_page = Int(PER_PAGE)!
        
        // A value of a page variable is estimated based on the facts that Flick return at most 4,000 images given any search query, and we set per_page parameter '21'.
        // This value means a possibel maximum number of pages that we have.
        
        let page = Int(TOTAL_PAGE/per_page)
        let randomPage = Int(arc4random_uniform(UInt32(page))+1)
        
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
        
        fetchImages(methodArguments)
        
    }
    
    // MARK : - Text Update
    
    func updateBottomButton() {
        if selectedIndexes.count > 0  {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }

}