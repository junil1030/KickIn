//
//  RecentEstateRepository.swift
//  KickIn
//
//  Created by 서준일 on 01/24/26.
//

import Foundation
import RealmSwift
import OSLog

final class RecentEstateRepository: RecentEstateRepositoryProtocol {
    private let actor: RealmActor

    init(configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration) {
        self.actor = RealmActor(configuration: configuration)
    }

    // MARK: - CRUD Operations

    func saveEstate(
        estateId: String,
        category: String?,
        deposit: Int?,
        monthlyRent: Int?,
        latitude: Double?,
        longitude: Double?,
        area: Double?,
        thumbnailURL: String?
    ) async throws {
        try await actor.write { realm in
            let estate = RecentEstateObject()
            estate.estateId = estateId
            estate.category = category
            estate.deposit = deposit
            estate.monthlyRent = monthlyRent
            estate.latitude = latitude
            estate.longitude = longitude
            estate.area = area
            estate.thumbnailURL = thumbnailURL
            estate.visitedAt = Date()

            realm.add(estate, update: .modified)  // upsert

            // 10개 초과 시 가장 오래된 항목 삭제
            let allEstates = realm.objects(RecentEstateObject.self)
                .sorted(byKeyPath: "visitedAt", ascending: false)
            if allEstates.count > 10 {
                let estatesToDelete = Array(allEstates.dropFirst(10))
                realm.delete(estatesToDelete)
            }
        }
        Logger.database.info("💾 Saved estate to recent: \(estateId)")
    }

    func fetchRecentEstatesAsUIModels(limit: Int) async throws -> [RecentEstateUIModel] {
        try await actor.read { realm in
            let results = realm.objects(RecentEstateObject.self)
                .sorted(byKeyPath: "visitedAt", ascending: false)
                .prefix(limit)

            // RealmActor 내부에서 UIModel로 변환
            return results.map { estate in
                RecentEstateUIModel(
                    estateId: estate.estateId,
                    category: estate.category,
                    deposit: estate.deposit,
                    monthlyRent: estate.monthlyRent,
                    latitude: estate.latitude,
                    longitude: estate.longitude,
                    area: estate.area,
                    thumbnailURL: estate.thumbnailURL
                )
            }
        }
    }

    func deleteEstate(estateId: String) async throws {
        try await actor.write { realm in
            if let estate = realm.object(ofType: RecentEstateObject.self, forPrimaryKey: estateId) {
                realm.delete(estate)
                Logger.database.info("🗑️ Deleted recent estate: \(estateId)")
            }
        }
    }

    func deleteAllEstates() async throws {
        try await actor.write { realm in
            let allEstates = realm.objects(RecentEstateObject.self)
            realm.delete(allEstates)
            Logger.database.info("🗑️ Deleted all recent estates")
        }
    }
}
