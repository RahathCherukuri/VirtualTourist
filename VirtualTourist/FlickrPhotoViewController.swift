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
    
    var coordinate: CLLocationCoordinate2D?
    
    var photoArray: [Photos] = []
    
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
        setCollectionView()
    }
    
    func setCollectionView() {
        
        methodArguments["lat"] = coordinate?.latitude
        methodArguments["lon"] = coordinate?.longitude
        methodArguments["page"] = 0
        getImagesFromFlickr()
    }
    
    @IBAction func bottomButtonPressed(sender: UIButton) {
        var array = [NSIndexPath]()
        if selectedIndexes.count > 0 {
            print("Delete items")
            _ = selectedIndexes.map({
                photoArray.removeAtIndex($0.row)
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
                self.photoArray.removeAll()
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
                photoArray.append(Photos(dictionary: $0))
            })
        }
    }
}

extension FlickrPhotoViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCollectionViewCell", forIndexPath: indexPath) as! FlickrCollectionViewCell
        
        if photoArray.count > 0 {
            let photo = photoArray[indexPath.row]
            
            let imageUrlString = photo.url
            let imageURL = NSURL(string: imageUrlString)
            if let imageData = NSData(contentsOfURL: imageURL!) {
                dispatch_async(dispatch_get_main_queue(), {
                    cell.imageView.image = UIImage(data: imageData)
                })
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








