//
//  Photo.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation


struct photo {
    
    static var photoArray: [photo] = []
    
    let title: String
    let url: String
    
    init(title: String, url: String) {
        self.title = title
        self.url = url
        photo.photoArray.append(self)
    }
}

class Data {
    static var DataCollectionViewOne: [photo] = []
}