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
        mapView.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        loadMapRegion(true)
        addLongPressGestureRecognizer()
        addBarButtonItem()
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
                
        let pin = Pin(latitude: touchMapCoordinate.latitude,longitude: touchMapCoordinate.longitude, context: sharedContext)
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
    
    // Helpers for initialmapload
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        print("saveMapRegion: ", dictionary["latitude"],dictionary["longitude"],dictionary["latitudeDelta"], dictionary["longitudeDelta"])
        
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func loadMapRegion(animated: Bool) {
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            
            let latitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let longitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            print("loadMapRegion: ", center.latitude,center.longitude,span.latitudeDelta, span.longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if (recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended) {
                    return true
                }
            }
        }
        return false
    }

}

extension ViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if mapViewRegionDidChangeFromUserInteraction() {
            saveMapRegion()
        }
        
    }

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
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        pins = fetchAllPins()
        _ = pins.map({
            addAnnotation(convertPinToAnnotation($0))
        })
    }

    // This function compares two annotations and returns the negative.
    func compareAnnotations(annotation: CLLocationCoordinate2D, selectedAnnotation: CLLocationCoordinate2D) -> Bool {
        return !((annotation.latitude == selectedAnnotation.latitude) && (annotation.longitude == selectedAnnotation.longitude))
    }

}
