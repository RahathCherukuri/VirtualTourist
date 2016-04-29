//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var deleteItemsButton: UIButton!
    
    @IBOutlet weak var editItemsButton: UIBarButtonItem!
    
    var annotations: Array = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        addLongPressGestureRecognizer()
        mapView.delegate = self
        deleteItemsButton.hidden = true
    }

    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        if (editItemsButton.title == "Edit") {
            deleteItemsButton.hidden = false
        } else if (editItemsButton.title == "Done") {
            deleteItemsButton.hidden = false
        }
        let title = (editItemsButton.title == "Edit") ? "Edit" : "Done"
        editItemsButton.title = title
    }
    
    @IBAction func deleteAnnotations(sender: UIButton) {
        
    }
    
    func addLongPressGestureRecognizer() {
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.handleLongPress(_:)))
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    func handleLongPress(gestureRecognizer : UIGestureRecognizer){
        if gestureRecognizer.state != .Began { return }
        
        let touchPoint = gestureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        print("latitude: ", touchMapCoordinate.latitude)
        print("longitude: ", touchMapCoordinate.longitude)
        annotations.append(annotation)
        mapView.addAnnotation(annotation)
    }
}

extension ViewController: MKMapViewDelegate {
    
    // Returns the view associated with the specified annotation object.
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        print("viewForAnnotation")
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
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
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("Selected")
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        print("De-selected")
    }
}



