//
//  QuadBox.swift
//  KickIn
//
//  Created by 서준일 on 1/9/26.
//

import CoreLocation

struct QuadBox {
    let xMin, yMin, xMax, yMax: Double
    
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        return (xMin...xMax).contains(coordinate.longitude) &&
        (yMin...yMax).contains(coordinate.latitude)
    }
    
    func intersects(_ other: QuadBox) -> Bool {
        return xMin <= other.xMax && xMax >= other.xMin &&
        yMin <= other.yMax && yMax >= other.yMin
    }
}
