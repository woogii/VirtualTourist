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



class TravelLocationsViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var editNoticeLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomInfoView: UIView!
    @IBOutlet weak var rightBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var bottomLayout: NSLayoutConstraint!
    
    var editMode:Bool = false
    var longGesture:UILongPressGestureRecognizer!
    var tapGesture:UITapGestureRecognizer!
    var pins = [Pin]()
    var latitude:Double!
    var longitude:Double!
    
    // MARK: - Life Cycle 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        longGesture = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longGesture!.minimumPressDuration = 0.5
        
        tapGesture = UITapGestureRecognizer(target: self, action: "removeAnnotation:")
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self      // set delegation to self for using delegate method
        
        mapView.addGestureRecognizer(longGesture)
        mapView.addGestureRecognizer(tapGesture)
        
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
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
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
        
        if editMode {
            
            editMode = false
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:"Edit", style:.Plain , target: self, action: "editButtonClicked:")
            
            UIView.animateWithDuration(0.5, delay: 0.0, options: [], animations: {
                
                self.bottomInfoView.alpha = 0
                self.bottomLayout.constant = -20
                self.view.layoutIfNeeded()
                
                }, completion: nil)
        
        } else {
            
            editMode = true
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:"Done" ,style:.Done, target: self, action: "editButtonClicked:")
            
            UIView.animateWithDuration(0.5, delay: 0.0, options: [], animations: {
                
                self.bottomInfoView.alpha = 1
                self.bottomLayout.constant = 0
                self.view.layoutIfNeeded()
                self.mapView.frame.origin.y -= self.bottomInfoView.frame.height
                
                }, completion: nil)
            
        }
    }

    // MARK: - Gesture actions
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        
        if ( gestureRecognizer.state == UIGestureRecognizerState.Ended) {
            return
        }
        
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        
        let dictionary:[String:AnyObject] = [
            Pin.Keys.Latitude  :  Double(newCoordinates.latitude),
            Pin.Keys.Longitude :  Double(newCoordinates.longitude)
        ]

        mapView.addAnnotation(annotation)
        let pin = Pin(dictionary: dictionary, context: sharedContext)
        pins.append(pin)
        
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func removeAnnotation(gestureRecognizer:UIGestureRecognizer) {
        
        if ( gestureRecognizer.state == UIGestureRecognizerState.Ended) {
            return
        }
        
//        let annotation = MKPointAnnotation()
//        annotation.coordinate.longitude = self.longitude
//        annotation.coordinate.latitude = self.latitude
//        
//      
//        mapView.removeAnnotation(annotation)
        

        for annotation in mapView.annotations {
        
            if annotation.coordinate.latitude == latitude && annotation.coordinate.longitude == longitude {
                mapView.removeAnnotation(annotation)
            }
            
        }
        
        for pin in pins  {
            if ( pin.longitude == longitude && pin.latitude == latitude ) {
                print("match")
                pins.removeObject(pin)
                sharedContext.deleteObject(pin)
                CoreDataStackManager.sharedInstance().saveContext()
                break
            }
        }

        print("count : \(pins.count)")
        
    }
    
    // MARK: - MKMapViewDelegate functions
    
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
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        longitude = view.annotation!.coordinate.longitude
        latitude  = view.annotation!.coordinate.latitude
        
        print(editMode)
        
        if (!editMode) {
            
            let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumViewController
            
            for pin in pins  {
                if ( pin.longitude == longitude && pin.latitude == latitude ) {
                    controller.longitude = self.longitude
                    controller.latitude = self.latitude
                    controller.pin = pin
                    break
                }
            }
            
            navigationController?.pushViewController(controller, animated: true)
            
        } else {
           
            print(longitude)
            print(latitude)
            removeAnnotation(tapGesture)
        }
    }
    
    
    // This method allows the view controller to be notified whenever the map region changes. So that it can save the new region.
    func mapView(mapView:MKMapView, regionDidChangeAnimated animated:Bool) {
        saveMapRegion()
    }
   
    // MARK : - UIGestureRecognizer Delegate 
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if (editMode){
            return true     // only allow tap gesture when the application is in editing mode
        } else {
            return false
        }
        
    }
}

extension RangeReplaceableCollectionType where Generator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            print("index :\(index)")
            self.removeAtIndex(index)
        }
    }
}


