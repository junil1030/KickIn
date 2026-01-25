//
//  RecentEstateRepositoryProtocol.swift
//  KickIn
//
//  Created by 서준일 on 01/24/26.
//

import Foundation

protocol RecentEstateRepositoryProtocol {
    func saveEstate(
        estateId: String,
        category: String?,
        deposit: Int?,
        monthlyRent: Int?,
        latitude: Double?,
        longitude: Double?,
        area: Double?,
        thumbnailURL: String?
    ) async throws
    func fetchRecentEstatesAsUIModels(limit: Int) async throws -> [RecentEstateUIModel]
    func deleteEstate(estateId: String) async throws
    func deleteAllEstates() async throws
}
