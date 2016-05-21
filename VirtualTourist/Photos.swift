//
//  Photo.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit

class Photos {
    
    var title: String
    var imagePath: String?
    
    init(dictionary: [String : AnyObject]) {
        title = dictionary[FlickrClient.JSONResponseKeys.Title] as! String
        imagePath = dictionary[FlickrClient.JSONResponseKeys.Url] as? String
    }
    
    var image: UIImage? {
        get { return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath) }
        set { FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!) }
    }
    
}