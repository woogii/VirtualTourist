//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Hyun on 2015. 11. 29..
//  Copyright © 2015년 wook2. All rights reserved.
//

import UIKit
import MapKit
import CoreData



class TravelLocationsViewController: UIViewController, MKMapViewDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var editNoticeLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomInfoView: UIView!
    @IBOutlet weak var rightBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var bottomLayout: NSLayoutConstraint!
    
    var isEdit:Bool = true
    var longGesture:UILongPressGestureRecognizer!
    var pins = [Pin]()
    var selectedPin:Pin!
    
    // MARK: - Life Cycle 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        longGesture = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longGesture!.minimumPressDuration = 0.5
        
        mapView.addGestureRecognizer(longGesture)
        mapView.delegate = self
        
        pins = fetchAllPins()
        
        if pins.count != 0 {
            restorePins()
        }
        
        restoreMapRegion(false)
    }
    
    func restorePins() {
        
        // We will create an MKPointAnnotation for each dictionary in "locations". The
        // point annotations will be stored in this array, and then provided to the map view.
        var annotations = [MKPointAnnotation]()
        
        // The "locations" array is loaded with the sample data below. We are using the dictionaries
        // to create map annotations. This would be more stylish if the dictionaries were being
        // used to create custom structs. Perhaps StudentLocation structs.
        
        for pin in pins {
            
            // Notice that the float values are being used to create CLLocationDegree values.
            // This is a version of the Double type.
            let lat = CLLocationDegrees(pin.latitude as Double)
            let long = CLLocationDegrees(pin.longitude as Double)
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        
        // When the array is complete, we add the annotations to the map.
        self.mapView.addAnnotations(annotations)
        

    }

    override func viewWillAppear(animated: Bool) {
        //title = "Virtual Tourist"
        bottomInfoView.alpha = 0
        bottomLayout.constant = -20
        view.layoutIfNeeded()
        print(mapView.frame.origin.y)
    }
    
    // MARK: - Computed Property
    
    var filePath : String {
        
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    // MARK: - Core Data Convenience 
    
    lazy var sharedContext : NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    } ()
    
    func fetchAllPins()->[Pin] {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            print("\(error.localizedDescription)")
            return [Pin]()
        }
    }
    
    // MARK : - Persist map coordinate
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary  
        // The "span" is the width and height of the map in degrees which represents the zoom level of the map
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude": mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // If we can unarchive a dictionary, we will use it to set the map back to its previous center and span 
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String:AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude  = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let saveRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(saveRegion, animated: animated)
            
        }
        
    }
    
    
    // MARK: - Action
    
    @IBAction func editButtonClicked(sender: UIBarButtonItem) {
        
        if isEdit {
            
            isEdit = false
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:"Done" ,style:.Done, target: self, action: "editButtonClicked:")
            
            //bottomInfoView.hidden = false
            
            UIView.animateWithDuration(0.5, delay: 0.0, options: [], animations: {
               
                self.bottomInfoView.alpha = 1
                self.bottomLayout.constant = 0
                self.view.layoutIfNeeded()
                self.mapView.frame.origin.y -= self.bottomInfoView.frame.height
                
            }, completion: nil)
            

        } else {
            
            isEdit = true
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:"Edit", style:.Plain , target: self, action: "editButtonClicked:")
            
            UIView.animateWithDuration(0.5, delay: 0.0, options: [], animations: {
                
                self.bottomInfoView.alpha = 0
                self.bottomLayout.constant = -20
                self.view.layoutIfNeeded()

            }, completion: nil)
            
        }
    }

    // MARK: - Get coordinate information
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        
        if ( gestureRecognizer.state == UIGestureRecognizerState.Ended) {
            return
        }
        
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        
        //let zoomLevel = getZoomLevel()
        
        let dictionary:[String:AnyObject] = [
            //Pin.Keys.ZoomLevel :  zoomLevel,
            Pin.Keys.Latitude  :  Double(newCoordinates.latitude),
            Pin.Keys.Longitude :  Double(newCoordinates.longitude)
        ]

        mapView.addAnnotation(annotation)
        _ = Pin(dictionary: dictionary, context: sharedContext)
        
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // MARK: - MKMapViewDelegate functions
    
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
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumViewController
        controller.longitude = view.annotation?.coordinate.longitude
        controller.latitude  = view.annotation?.coordinate.latitude
        
        let dictionary:[String:AnyObject] = [
            //Pin.Keys.ZoomLevel :  zoomLevel,
            Pin.Keys.Latitude  :  Double(controller.latitude),
            Pin.Keys.Longitude :  Double(controller.longitude)
        ]
        
        controller.pin = pin
            
        // controller.pin = Pin(dictionary: dictionary, context: sharedContext)
      
        navigationController?.pushViewController(controller, animated: true)
    
    }
    
    
    // This method allows the view controller to be notified whenever the map region changes. So that it can save the new region.
    func mapView(mapView:MKMapView, regionDidChangeAnimated animated:Bool) {
        saveMapRegion()
    }
   
    
}

