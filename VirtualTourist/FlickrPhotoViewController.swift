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
    
    var selectedIndexes = Set<NSIndexPath>();
    
    var coordinate: CLLocationCoordinate2D?
    
    var photoArray: [Photos] = []
    
    var methodArguments: [String: AnyObject] = [
        "method": METHOD_NAME,
        "api_key": API_KEY,
        "safe_search": SAFE_SEARCH,
        "extras": EXTRAS,
        "format": DATA_FORMAT,
        "nojsoncallback": NO_JSON_CALLBACK
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        flickrCollectionView.allowsMultipleSelection = true
        setCollectionView()
    }
    
    func setCollectionView() {
        
        methodArguments["lat"] = coordinate?.latitude
        methodArguments["lon"] = coordinate?.longitude
        
        FlickrClient.sharedInstance().getImageFromFlickrBySearch(methodArguments) {(success, photos, errorString) in
            if success {
                self.savePhotoData(photos!)
                dispatch_async(dispatch_get_main_queue(), {
                    self.flickrCollectionView.reloadData()
                })
            } else {
                print("Error: ", errorString)
            }
        }
    }
    
    @IBAction func bottomButtonPressed(sender: UIButton) {
        var array = [NSIndexPath]()
        if selectedIndexes.count > 0 {
            for index in selectedIndexes {
                photoArray.removeAtIndex(index.row)
                array.append(index)
            }
            flickrCollectionView.deleteItemsAtIndexPaths(array)
            selectedIndexes.removeAll()
        }
    }
    
    func savePhotoData(photos: [String: AnyObject]) {
        
        let totalPhotosCount = (photos[FlickrClient.JSONResponseKeys.Totalphotos] as? NSString)?.integerValue
        
        if (totalPhotosCount > 0) {
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photos[FlickrClient.JSONResponseKeys.Photo] as? [[String: AnyObject]] where photosArray.count > 0 else {
                print("Cannot find key 'photo' in \(photos)")
                return
            }
            
            for photoDictionary in photosArray {
                /* GUARD: Does our photo have a key for 'url_m'? */
                guard let imageUrlString = photoDictionary[FlickrClient.JSONResponseKeys.Url] as? String,
                    let photoTitle = photoDictionary[FlickrClient.JSONResponseKeys.Title] as? String
                    else {
                        print("Cannot find key 'url_m' in \(photoDictionary)")
                        return
                }
                let photo = Photos(title: photoTitle,url: imageUrlString)
                photoArray.append(photo)
            }
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








