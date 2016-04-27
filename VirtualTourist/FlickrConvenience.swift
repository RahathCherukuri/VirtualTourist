//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation
import UIKit

extension FlickrClient {
    
    func getImageFromFlickrBySearch(parameters: [String: AnyObject],completionHandler: (success: Bool, results: [String: AnyObject]?, errorString: String?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let method: String = METHOD_NAME
        /* 2. Make the request */
        taskForGETMethod(method, parameters: parameters) {(JSONResult, error) in
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                print("error: ", error)
                completionHandler(success: false, results: nil, errorString: "Please check your internet connection and try again.")
            } else {
                /* GUARD: Is "photos" key in our result? */
                guard let photos = JSONResult[FlickrClient.JSONResponseKeys.Photos] as? [String: AnyObject] else {
                    completionHandler(success: false, results: nil, errorString: "Cannot find keys 'photos'")
                    return
                }
                completionHandler(success: true, results: photos, errorString: nil)
            }
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
                Photos(title: photoTitle,url: imageUrlString)
            }
        }
    }
    
}

