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
    
    var annotations: Array = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        addLongPressGestureRecognizer()
        addBarButtonItem()
        mapView.delegate = self
        deleteItemsButton.hidden = true
    }
    
    func addBarButtonItem() {
        let editButton = UIBarButtonItem.init(title: "Edit", style: .Plain, target:self, action: #selector(ViewController.editButtonPressed(_:)))
        navigationController?.navigationBar.topItem?.rightBarButtonItem = editButton
    }

    func editButtonPressed(sender: UIBarButtonItem?) {
        setRightBarButtonAndBottomButton()
        annotations.map({
            print($0.coordinate)
        })
    }
    
    @IBAction func deleteAnnotations(sender: UIButton) {
        setRightBarButtonAndBottomButton()
    }
    
    func setRightBarButtonAndBottomButton() {
        let title = getRightBarButtonItemTitle()
        deleteItemsButton.hidden = (title == "Edit") ? false : true
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = (title == "Edit") ? "Done" : "Edit"
    }
    
    func getRightBarButtonItemTitle() -> String? {
        return navigationController?.navigationBar.topItem?.rightBarButtonItem?.title
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
        annotations.append(annotation)
        mapView.addAnnotation(annotation)
    }
}

extension ViewController: MKMapViewDelegate {
    
    // Returns the view associated with the specified annotation object.
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        else {
            pinView!.annotation = annotation
            pinView?.pinTintColor = UIColor.blueColor()
        }
        
        return pinView
    }
    
//     // This delegate method is implemented to respond to taps.
//    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//        if control == annotationView.rightCalloutAccessoryView {
//            
//            let coordinate = annotationView.annotation?.coordinate
//            let latitude = coordinate?.latitude
//            let longitude = coordinate?.longitude
//        
//            print("latitude: ", latitude)
//            print("longitude: ", longitude)
//        }
//    }
    
    // TODO: Remove items from array once selected.
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("Selected")
        let title = getRightBarButtonItemTitle()

        if (title == "Done") {
            mapView.removeAnnotation((view.annotation)!)
            return
        }
        
        // If title is Edit
        let controller = storyboard?.instantiateViewControllerWithIdentifier("FlickrPhotoViewController") as! FlickrPhotoViewController
        controller.coordinate = view.annotation?.coordinate
        navigationController?.pushViewController(controller, animated: true)
    }

}



