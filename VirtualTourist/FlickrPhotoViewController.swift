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
        setCollectionView()
        // Do any additional setup after loading the view.
    }
    
    func setCollectionView() {
        
        let searchText = "NewYork, NY"
        print("Random Text: ", searchText)
        methodArguments["text"] = searchText
        
        FlickrClient.sharedInstance().getImageFromFlickrBySearch(methodArguments) {(success, photos, errorString) in
            if success {
                FlickrClient.sharedInstance().savePhotoData(photos!, index: 0)
                dispatch_async(dispatch_get_main_queue(), {
                    self.flickrCollectionView.reloadData()
                })
            } else {
                print("Error: ", errorString)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return Data.DataCollectionViewOne.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCollectionViewCell", forIndexPath: indexPath) as! FlickrCollectionViewCell
            
            if Data.DataCollectionViewOne.count > 0 {
                let photo = Data.DataCollectionViewOne[indexPath.row]
                
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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        //        let detailController = storyboard!.instantiateViewControllerWithIdentifier("MemeDetailViewController") as! MemeDetailViewController
        //        detailController.selectedIndex = indexPath.row
        //        navigationController!.pushViewController(detailController, animated: true)
    }


}
