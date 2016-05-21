//
//  FlickrPhotoViewController.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit
import MapKit

class FlickrPhotoViewController: UIViewController {
    
    @IBOutlet weak var flickrCollectionView: UICollectionView!
    
    @IBOutlet weak var bottomBarButton: UIButton!
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        flickrCollectionView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if pin.photos.isEmpty {
            setCollectionView()
        }
    }
    
    func setCollectionView() {
        methodArguments["lat"] = pin.latitude
        methodArguments["lon"] = pin.longitude
        methodArguments["page"] = 0
        getImagesFromFlickr()
    }
    
    @IBAction func bottomButtonPressed(sender: UIButton) {
        var array = [NSIndexPath]()
        if selectedIndexes.count > 0 {
            print("Delete items")
            _ = selectedIndexes.map({
                pin.photos.removeAtIndex($0.row)
                array.append($0)
            })
            flickrCollectionView.deleteItemsAtIndexPaths(array)
            selectedIndexes.removeAll()
        } else {
            methodArguments["page"] = randomValue(pages!)
            getImagesFromFlickr()
        }
    }
    
    func getImagesFromFlickr() {
        FlickrClient.sharedInstance().getImageFromFlickrBySearch(methodArguments) {(success, photos, errorString) in
            if success {
                self.pin.photos.removeAll()
                self.savePhotoData(photos!)
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.flickrCollectionView.reloadData()
                })
            } else {
                print("Error: ", errorString)
            }
        }
    }
    
    /* Flickr API will only return up the 4000 images (50 per page * 80 page max) */
    /* Pick a random page! */
    
    func randomValue(noOfPages: Int) -> Int {
        let pageLimit = min(noOfPages, 80)
        return Int(arc4random_uniform(UInt32(pageLimit))) + 1
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
                let photo = Photos(dictionary: $0)
                pin.photos.append(photo)
//                photoArray.append(photo)
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
            let photo = pin.photos[indexPath.row]
            if let localImage = photo.image {
                cell.imageView.image = localImage
            } else if photo.imagePath == nil || photo.imagePath == "" {
                print("imagePath is nil")
            } else {
                let imageUrlString = photo.imagePath
                let imageURL = NSURL(string: imageUrlString!)
                if let imageData = NSData(contentsOfURL: imageURL!) {
                    let image = UIImage(data: imageData)
                    photo.image = image
                    dispatch_async(dispatch_get_main_queue(), {
                        cell.imageView.image = image
                    })
                }
            }
            setCellOpacity(cell)
            return cell
        } else {
            return cell
        }
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








