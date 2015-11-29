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
        longGesture!.minimumPressDuration = 1.0
        
        mapView.addGestureRecognizer(longGesture)
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
                // print(self.bottomInfoView.frame.height)   // 83
                // print(self.mapView.frame.origin.y)        // 64

            }, completion: nil)
            
        }
    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        annotation.title = ""
        mapView.addAnnotation(annotation)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            //pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
 
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        navigationController?.pushViewController(controller, animated: true)
    
    }
    
    
}

