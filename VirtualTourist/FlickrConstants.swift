//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "f7789d295e6e0e090c774d52d32e8741"
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

extension FlickrClient {
    
    struct JSONResponseKeys {
        
        static let Photos = "photos"
        static let Photo = "photo"
        static let Totalphotos = "total"
        static let Title = "title"
        static let Url = "url_m"
        
    }
}
