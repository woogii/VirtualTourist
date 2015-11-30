//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Hyun on 2015. 11. 29..
//  Copyright © 2015년 wook2. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var editNoticeLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomInfoView: UIView!
    @IBOutlet weak var rightBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var bottomLayout: NSLayoutConstraint!
    
    var isEdit:Bool = true
    var longGesture:UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        longGesture = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longGesture!.minimumPressDuration = 0.5
        
        mapView.addGestureRecognizer(longGesture)
        mapView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        self.bottomInfoView.alpha = 0
        self.bottomLayout.constant = -20
        self.view.layoutIfNeeded()
        print(self.mapView.frame.origin.y)
    }
    
    
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
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        
        mapView.addAnnotation(annotation)
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
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumViewController
        navigationController?.pushViewController(controller, animated: true)
    
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
    
    func getZoomLevel() ->Double {
    
        
    
        let longitudeDelta:CLLocationDegrees = self.mapView.region.span.longitudeDelta
        let mapWidthInPixels:CGFloat  = self.mapView.bounds.size.width
        let zoomScale = (longitudeDelta * MERCATOR_RADIUS * M_PI) / Double(180.0 * mapWidthInPixels)
        var zoomer = MAX_GOOGLE_LEVELS - log2( zoomScale )
        
        if ( zoomer < 0 ) {
            zoomer = 0
        }
    
        return zoomer
    }
    
    
}