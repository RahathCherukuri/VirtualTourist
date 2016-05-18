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
    
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}