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
        self.bottomInfoView.alpha = 0
        self.bottomLayout.constant = -20
        self.view.layoutIfNeeded()
        print(self.mapView.frame.origin.y)
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
        print(Double(newCoordinates.latitude))
        print(Double(newCoordinates.longitude))
        print(dictionary)
        
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
        navigationController?.pushViewController(controller, animated: true)
    
    }
    
    // This method allows the view controller to be notified whenever the map region changes. So that it can save the new region.
    func mapView(mapView:MKMapView, regionDidChangeAnimated animated:Bool) {
        saveMapRegion()
    }
   
    
//    func mapView(mapView: MKMapView, didAddAnnotationViews views : [MKAnnotationView]) {
//  
//        for view in views {
//            
//            let endFrame = view.frame
//            
//            view.frame = CGRectMake(view.frame.origin.x, 0.0, view.frame.size.width, view.frame.size.height)
//            view.alpha = 0
//            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveLinear, animations: {
//                view.alpha = 1
//                view.frame = endFrame
//                
//                }, completion: nil)
//            
//        }
//        
//    }
    
    
}

extension TravelLocationsViewController {
    
    
    private var MERCATOR_OFFSET: Double {
        get {
            return 268435456
        }
    }
    private var MERCATOR_RADIUS: Double {
        get {
            return 85445659.44705395
        }
    }
    
    private var MAX_GOOGLE_LEVELS: Double {
        get {
            return 20.0
        }
    }
    
    // MARK: -  Private functions
    private func longitudeToPixelSpaceX (longitude: Double) -> Double {
        return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0)
    }
    
    private func latitudeToPixelSpaceY (latitude: Double) -> Double {
        
        let a = 1 + sinf(Float(latitude * M_PI) / 180.0)
        let b = 1.0 - sinf(Float(latitude * M_PI / 180.0)) / 2.0
        
        return round(MERCATOR_OFFSET - MERCATOR_RADIUS * Double(logf(a / b)))
    }
    
    private func pixelSpaceXToLongitude (pixelX: Double) -> Double {
        return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI
    }
    
    private func pixelSpaceYToLatitude (pixelY: Double) -> Double {
        return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI
    }
    
    private func coordinateSpanWithMapView(mapView: MKMapView, centerCoordinate: CLLocationCoordinate2D, andZoomLevel zoomLevel:Int) -> MKCoordinateSpan {
        
        // convert center coordiate to pixel space
        let centerPixelX = self.longitudeToPixelSpaceX(centerCoordinate.longitude)
        let centerPixelY = self.latitudeToPixelSpaceY(centerCoordinate.latitude)
        
        // determine the scale value from the zoom level
        let zoomExponent = 20 - zoomLevel
        let zoomScale = CGFloat(pow(Double(2), Double(zoomExponent)))
        
        // scale the map’s size in pixel space
        let mapSizeInPixels = mapView.bounds.size
        let scaledMapWidth = mapSizeInPixels.width * zoomScale
        let scaledMapHeight = mapSizeInPixels.height * zoomScale
        
        // figure out the position of the top-left pixel
        let topLeftPixelX = CGFloat(centerPixelX) - (scaledMapWidth / 2)
        let topLeftPixelY = CGFloat(centerPixelY) - (scaledMapHeight / 2)
        
        // find delta between left and right longitudes
        let minLng: CLLocationDegrees = self.pixelSpaceXToLongitude(Double(topLeftPixelX))
        let maxLng: CLLocationDegrees = self.pixelSpaceXToLongitude(Double(topLeftPixelX + scaledMapWidth))
        let longitudeDelta: CLLocationDegrees = maxLng - minLng
        
        // find delta between top and bottom latitudes
        let minLat: CLLocationDegrees = self.pixelSpaceYToLatitude(Double(topLeftPixelY))
        let maxLat: CLLocationDegrees = self.pixelSpaceYToLatitude(Double(topLeftPixelY + scaledMapHeight))
        let latitudeDelta: CLLocationDegrees = -1 * (maxLat - minLat)
        
        // create and return the lat/lng span
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        
        return span
        
    }
    
    // MARK: - Public Functions
    
    func setCenterCoordinate(centerCoordinate: CLLocationCoordinate2D, zoomLevel: Int, animated: Bool) {
        
        // clamp large numbers to 28
        let zoom = min(zoomLevel, 28)
        
        // use the zoom level to compute the region
        let span = self.coordinateSpanWithMapView(self.mapView, centerCoordinate:centerCoordinate, andZoomLevel:zoom)
        let region = MKCoordinateRegionMake(centerCoordinate, span)
        
        // set the region like normal
        self.mapView.setRegion(region, animated:animated)
        
    }
    
    func getZoomLevel() -> Int {
    
        let longitudeDelta:CLLocationDegrees = self.mapView.region.span.longitudeDelta
        let mapWidthInPixels:CGFloat  = self.mapView.bounds.size.width
        let zoomScale = (longitudeDelta * MERCATOR_RADIUS * M_PI) / Double(180.0 * mapWidthInPixels)
        var zoomer = MAX_GOOGLE_LEVELS - log2( zoomScale )
        
        if ( zoomer < 0 ) {
            zoomer = 0
        }
    
        return Int(zoomer)
    }
    
    
}