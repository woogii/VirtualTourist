//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Hyun on 2015. 11. 29..
//  Copyright © 2015년 wook2. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate {

    let identifier = "PhotoCell"
    let regionRadius: CLLocationDistance = 3000

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var miniMapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    var pics =  [Picture]()
    var longitude:Double!
    var latitude : Double!
    
    // MARK : - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(center,
            regionRadius * 2.0, regionRadius * 2.0)
        
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        
        //let zoomLevel = getZoomLevel()
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
                    
                    //if let totalPages = photoDictionary["pages"] as? Int {
                        
                        // Flickr API - will only return up the 4000 images ( 100 per page, 40 page max)
                        //let page = min(totalPages, 40)
                        //let randomPage = Int(arc4random_uniform(UInt32(page))+1)
                        
                        
                        if let photoArray = photoDictionary["photo"] as? [[String:AnyObject]] {
                            print("photoArray: \(photoArray.count)")
                            //let photoDictionary = photoArray[randomPage] as [String:AnyObject]
                            //let photo = photoArray[randomPage] as [String:AnyObject]
                            let pics = photoArray.map() { (dictionary:[String:AnyObject])->Picture in
                                return Picture(dictionary:dictionary)
                            }
                            
                            print(pics.count)
                            self.pics = pics
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.collectionView.reloadData()
                             
                            }
                            
                        }
                    //}
                }
            }
        }

    }

    func createBoundingBoxString(longitude:Double, latitude:Double)->String {
        
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_WIDTH, LON_MAX)
        
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        print("\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)")
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }

    
    func alertViewForError(error:NSError) {
        let alertView = UIAlertController(title: "", message: "\(error.localizedDescription)" , preferredStyle: .Alert)
        alertView.addAction(UIAlertAction(title: "Dismiss", style:.Default, handler: nil))
        presentViewController(alertView, animated: true, completion: nil)
    }
    
    
    // MARK: - Delegate Methods
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pics.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! PhotoCell
        var cellImage = UIImage(named: "placeholder")

        cell.imageView!.image = nil
        cell.activityIndicator.startAnimating()
        
        let pic = pics[indexPath.row]
        
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
        //cell.activityIndicator.stopAnimating()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        
    }
    
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
            //pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        pinView?.animatesDrop = true
        return pinView
        
    }

    


}