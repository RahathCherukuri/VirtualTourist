//
//  Pin.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 5/18/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation
import MapKit

class Pin {
    
    var latitude: Double
    var longitude: Double
    var photos: [Photos] = [Photos]()
    
    init(coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }
}