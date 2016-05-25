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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMapView()
        flickrCollectionView.allowsMultipleSelection = true
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
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
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
            flickrCollectionView.deleteItemsAtIndexPaths(array)
            selectedIndexes.removeAll()
            setbottomBarButtonText()
            
        } else {
            _ = pin.photos.map({
                $0.location = nil
                // Remove the photo from the context
                sharedContext.deleteObject($0)
                saveContext()
            })
            flickrCollectionView.reloadData()
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
//                self.pin.photos.removeAll()
                self.savePhotoData(photos!)
                dispatch_async(dispatch_get_main_queue(), {
                    self.flickrCollectionView.reloadData()
                })
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
        return pin.photos.count
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
        let photo = pin.photos[indexPath.row]
        if let localImage = photo.image {
            print("image Present")
            stopAndHideSpinner(cell)
            cell.imageView.image = localImage
        } else if photo.imagePath == nil || photo.imagePath == "" {
            print("imagePath is nil")
            stopAndHideSpinner(cell)
        } else {
            print("No Image")
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
//        print("didSelectItemAtIndexPath indexPath: ", indexPath.row)
        selectedIndexes.insert(indexPath)
        let cell = collectionView.cellForItemAtIndexPath(indexPath)! as? FlickrCollectionViewCell
        setCellOpacity(cell!)
        setbottomBarButtonText()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
//        print("didDeselectItemAtIndexPath indexPath: ", indexPath.row)
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
        let cellSize = screenWidth.width/3.25
        return CGSize(width: cellSize,height: cellSize)
    }
}








