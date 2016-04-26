//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController,MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        addLongPressGestureRecognizer()
        mapView.delegate = self
    }

    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        
    }
    
    func addLongPressGestureRecognizer() {
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.handleLongPress(_:)))
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        annotation.title = "\(annotation.coordinate.latitude)"
        annotation.subtitle = "\(annotation.coordinate.longitude)"
        print("latitude: ", touchMapCoordinate.latitude)
        print("longitude: ", touchMapCoordinate.longitude)
        mapView.addAnnotation(annotation)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        print("viewForAnnotation")
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps.
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("clicked")
        if control == annotationView.rightCalloutAccessoryView {
            print("mapView delegate method")
            let latitude = annotationView.annotation?.coordinate.latitude
            let longitude = annotationView.annotation?.coordinate.longitude
            print("latitude: ", latitude)
            print("longitude: ", longitude)
        }
    }
}

