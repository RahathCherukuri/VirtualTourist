//
//  Photo.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import UIKit
import CoreData

class Photo: NSManagedObject {
    
    @NSManaged var title: String
    @NSManaged var imagePath: String?
    @NSManaged var location: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        title = dictionary[FlickrClient.JSONResponseKeys.Title] as! String
        imagePath = dictionary[FlickrClient.JSONResponseKeys.Url] as? String
    }
    
    var image: UIImage? {
        get { return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath) }
        set { FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!) }
    }
}