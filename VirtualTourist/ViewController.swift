//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var deleteItemsButton: UIButton!

    var pins = [Pin]()
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            print("Error in fetchAllActors(): \(error)")
            return [Pin]()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        pins = fetchAllPins()
        print("pins.count: ", pins.count)
        _ = pins.map({
            addAnnotation(convertPinToAnnotation($0))
        })
        addLongPressGestureRecognizer()
        addBarButtonItem()
        mapView.delegate = self
        deleteItemsButton.hidden = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    func addBarButtonItem() {
        let editButton = UIBarButtonItem.init(title: "Edit", style: .Plain, target:self, action: #selector(ViewController.editButtonPressed(_:)))
        navigationController?.navigationBar.topItem?.rightBarButtonItem = editButton
    }

    func editButtonPressed(sender: UIBarButtonItem?) {
        setRightBarButtonAndBottomButton()
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

        let pin = Pin(coordinate: touchMapCoordinate, context: sharedContext)
        saveContext()
        pins.append(pin)
        addAnnotation(convertPinToAnnotation(pin))
    }

    func convertPinToAnnotation(pin: Pin) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        return annotation
    }
    
    func addAnnotation(annotation: MKPointAnnotation) {
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

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let title = getRightBarButtonItemTitle()
        if (title == "Done") {
            
            pins = pins.filter({
                let coordinate = CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                let bool = compareAnnotations(coordinate, selectedAnnotation: (view.annotation?.coordinate)!)
                if !bool {
                    sharedContext.deleteObject($0)
                    saveContext()
                }
                return bool
            })
            mapView.removeAnnotation((view.annotation)!)
            return
        }
        // Deselecting map annotation.
        mapView.deselectAnnotation(view.annotation, animated: false)

        // If title is Edit
        let controller = storyboard?.instantiateViewControllerWithIdentifier("FlickrPhotoViewController") as! FlickrPhotoViewController

        _ = pins.map ({
            let selectedAnnotion = view.annotation?.coordinate
            let annotationInPins = CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            if (!compareAnnotations(annotationInPins, selectedAnnotation: selectedAnnotion!)) {
                controller.pin = $0
            }
        })

        navigationController?.pushViewController(controller, animated: true)
    }

    // This function compares two annotations and returns the negative.
    func compareAnnotations(annotation: CLLocationCoordinate2D, selectedAnnotation: CLLocationCoordinate2D) -> Bool {
        return !((annotation.latitude == selectedAnnotation.latitude) && (annotation.longitude == selectedAnnotation.longitude))
    }

}
