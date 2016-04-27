//
//  FlickrPhotoViewController.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class FlickrPhotoViewController: UIViewController {
    
    @IBOutlet weak var flickrCollectionView: UICollectionView!
    
    @IBOutlet weak var bottomBarButton: UIButton!
    
    var selectedIndexes = Set<NSIndexPath>();
    
    var methodArguments = [
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
        
        let searchText = "NewYork, NY"
        print("Random Text: ", searchText)
        methodArguments["text"] = searchText
        
        FlickrClient.sharedInstance().getImageFromFlickrBySearch(methodArguments) {(success, photos, errorString) in
            if success {
                FlickrClient.sharedInstance().savePhotoData(photos!)
                dispatch_async(dispatch_get_main_queue(), {
                    self.flickrCollectionView.reloadData()
                })
            } else {
                print("Error: ", errorString)
            }
        }
    }
    
    // TODO: Add Code to delete elements from the array(Photos.photoArray) and the flickrCollectionView
    @IBAction func bottomButtonPressed(sender: UIButton) {
        if selectedIndexes.count > 0 {
//            for indexPath in selectedIndexes {
//                print("row: ", indexPath.row)
//                
//            }
            
        }
    }
}

extension FlickrPhotoViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Photos.photoArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCollectionViewCell", forIndexPath: indexPath) as! FlickrCollectionViewCell
        
        if Photos.photoArray.count > 0 {
            let photo = Photos.photoArray[indexPath.row]
            
            let imageUrlString = photo.url
            let imageURL = NSURL(string: imageUrlString)
            if let imageData = NSData(contentsOfURL: imageURL!) {
                dispatch_async(dispatch_get_main_queue(), {
                    cell.imageView.image = UIImage(data: imageData)
                })
            }
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
        cell!.imageView.layer.opacity = 0.5
        setbottomBarButtonText()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
//        print("didDeselectItemAtIndexPath indexPath: ", indexPath.row)
        let cell = collectionView.cellForItemAtIndexPath(indexPath)! as? FlickrCollectionViewCell
        cell!.imageView.layer.opacity = 1
        selectedIndexes.remove(indexPath)
        setbottomBarButtonText()
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








