//
//  FlickrPhotoViewController.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class FlickrPhotoViewController: UIViewController {
    
    @IBOutlet weak var flickrCollectionView: UICollectionView!
    
    @IBOutlet weak var bottomBarButton: UIButton!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var pages: Int?
    
    var selectedIndexes = Set<NSIndexPath>();
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var pin: Pin!
    
    var methodArguments: [String: AnyObject] = [
        "method": METHOD_NAME,
        "api_key": API_KEY,
        "safe_search": SAFE_SEARCH,
        "extras": EXTRAS,
        "format": DATA_FORMAT,
        "nojsoncallback": NO_JSON_CALLBACK,
        "per_page": PER_PAGE
    ]
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMapView()
        flickrCollectionView.allowsMultipleSelection = true
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if pin.photos.isEmpty {
            methodArguments["page"] = 0
            setCollectionView()
        }
    }
    
    func loadMapView(){
        let center = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.75, longitudeDelta: 0.75)
        let savedRegion = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(savedRegion, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)
    }
    
    func setCollectionView() {
        setLatitudeLongitude()
        getImagesFromFlickr()
    }
    
    func setLatitudeLongitude() {
        methodArguments["lat"] = pin.latitude
        methodArguments["lon"] = pin.longitude
    }
    
    @IBAction func bottomButtonPressed(sender: UIButton) {
        var array = [NSIndexPath]()
        // To Delete items
        if selectedIndexes.count > 0 {
            print("Delete items")
            _ = selectedIndexes.map({
                let selectedPhoto = pin.photos[$0.row]
                selectedPhoto.location = nil
                
                // Remove the photo from the context
                sharedContext.deleteObject(selectedPhoto)
                saveContext()
                
                array.append($0)
            })
            selectedIndexes.removeAll()
            setbottomBarButtonText()
            
        } else {
            _ = pin.photos.map({
                $0.location = nil
                // Remove the photo from the context
                sharedContext.deleteObject($0)
                saveContext()
            })
            // To get new collection photos
            getNewImagesFromFlickr(){success, pages in
                if success {
                    self.methodArguments["page"] = self.randomValue(pages!)
                    self.setCollectionView()
                }
            }
        }
    }
    
    /* Flickr API will only return up the 4000 images (50 per page * 80 page max) */
    /* Pick a random page! */
    
    func randomValue(noOfPages: Int) -> Int {
        let pageLimit = min(noOfPages, 80)
        return Int(arc4random_uniform(UInt32(pageLimit))) + 1
    }
    
    func getImagesFromFlickr() {
        FlickrClient.sharedInstance().getImageFromFlickrBySearch(methodArguments) {(success, photos, errorString) in
            if success {
                self.savePhotoData(photos!)
                self.saveContext()
            } else {
                print("Error: ", errorString)
            }
        }
    }
    
    func getNewImagesFromFlickr(completionHandler: (success: Bool , pages: Int?) -> Void) {
        setLatitudeLongitude()
        FlickrClient.sharedInstance().getImageFromFlickrBySearch(methodArguments) {(success, photos, errorString) in
            if success {
                let totalPhotosCount = (photos![FlickrClient.JSONResponseKeys.Totalphotos] as? NSString)?.integerValue
                if (totalPhotosCount > 0) {
                    guard let totalPages = photos![FlickrClient.JSONResponseKeys.Pages] as? Int else {
                        print("Cannot find key")
                        return
                    }
                    completionHandler(success: true, pages: totalPages)
                }
            } else {
                print("Error: ", errorString)
                completionHandler(success: false, pages: nil)
            }
        }

    }
    
    func savePhotoData(photos: [String: AnyObject]) {
        
        let totalPhotosCount = (photos[FlickrClient.JSONResponseKeys.Totalphotos] as? NSString)?.integerValue
        
        if (totalPhotosCount > 0) {
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photos[FlickrClient.JSONResponseKeys.Photo] as? [[String: AnyObject]] where photosArray.count > 0,
                 let totalPages = photos[FlickrClient.JSONResponseKeys.Pages] as? Int
            else {
                print("Cannot find key 'photo' in \(photos)")
                return
            }
            
            pages = totalPages
            
            _ = photosArray.map({
                let photo = Photo(dictionary: $0, context: sharedContext)
                photo.location = self.pin
            })
            
        }
    }
}

extension FlickrPhotoViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCollectionViewCell", forIndexPath: indexPath) as! FlickrCollectionViewCell
        if pin.photos.count > 0 {
            configureCell(cell, forIndexPath: indexPath)
            return cell
        } else {
            return cell
        }
    }
    
    func configureCell(cell: FlickrCollectionViewCell, forIndexPath indexPath: NSIndexPath) {
        cell.spinner.startAnimating()
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let localImage = photo.image {
            stopAndHideSpinner(cell)
            cell.imageView.image = localImage
        } else if photo.imagePath == nil || photo.imagePath == "" {
            stopAndHideSpinner(cell)
        } else {
            let imageUrlString = photo.imagePath
            let imageURL = NSURL(string: imageUrlString!)
            FlickrClient.sharedInstance().taskForImage(imageURL!) {(data, error) in
                if error != nil {
                    print("Downloading error");
                } else {
                    let image = UIImage(data: data!)
                    photo.image = image
                    dispatch_async(dispatch_get_main_queue(), {
                        self.stopAndHideSpinner(cell)
                        cell.imageView.image = image
                        
                    })
                }
            }
        }
        setCellOpacity(cell)
    }
    
    func stopAndHideSpinner(cell: FlickrCollectionViewCell) {
        cell.spinner.stopAnimating()
        cell.spinner.hidden = true
    }

}

extension FlickrPhotoViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedIndexes.insert(indexPath)
        let cell = collectionView.cellForItemAtIndexPath(indexPath)! as? FlickrCollectionViewCell
        setCellOpacity(cell!)
        setbottomBarButtonText()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)! as? FlickrCollectionViewCell
        setCellOpacity(cell!)
        selectedIndexes.remove(indexPath)
        setbottomBarButtonText()
    }
    
    func setCellOpacity(cell: FlickrCollectionViewCell) {
        cell.imageView.layer.opacity = (cell.selected) ? 0.5 : 1
    }
    
    func setbottomBarButtonText() {
        print("selectedIndexes.count: ", selectedIndexes.count)
        let text = (selectedIndexes.count == 0) ? "New Collection" : "Remove Selected Items"
        bottomBarButton.setTitle(text,forState: .Normal)
    }
}

extension FlickrPhotoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let screenWidth = UIScreen.mainScreen().bounds.size
        let cellSize = screenWidth.width/3.03
        return CGSize(width: cellSize,height: cellSize)
    }
}

extension FlickrPhotoViewController: NSFetchedResultsControllerDelegate {
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            print("Insert an item")
            // Here we are noting that a new Photo instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            // Here we are noting that a Photo instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            // We don't expect Photo instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. 
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        flickrCollectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.flickrCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.flickrCollectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.flickrCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }

}








