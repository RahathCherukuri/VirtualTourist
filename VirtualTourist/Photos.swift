//
//  Photo.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation

class Photos {
    
    var title: String
    var url: String
    
    init(dictionary: [String : AnyObject]) {
        title = dictionary[FlickrClient.JSONResponseKeys.Title] as! String
        url = dictionary[FlickrClient.JSONResponseKeys.Url] as! String
    }
}