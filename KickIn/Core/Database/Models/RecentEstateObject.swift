//
//  RecentEstateObject.swift
//  KickIn
//
//  Created by 서준일 on 01/24/26.
//

import Foundation
import RealmSwift

final class RecentEstateObject: Object, Identifiable {
    @Persisted(primaryKey: true) var estateId: String
    @Persisted var category: String?
    @Persisted var deposit: Int?
    @Persisted var monthlyRent: Int?
    @Persisted var latitude: Double?
    @Persisted var longitude: Double?
    @Persisted var area: Double?
    @Persisted var thumbnailURL: String?
    @Persisted(indexed: true) var visitedAt: Date
}
