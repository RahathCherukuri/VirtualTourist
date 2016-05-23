//
//  Pin.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 5/18/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class Pin: NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    // Standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }
}