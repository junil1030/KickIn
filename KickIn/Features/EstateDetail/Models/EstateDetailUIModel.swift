//
//  EstateDetailUIModel.swift
//  KickIn
//
//  Created by 서준일 on 12/23/25.
//

import Foundation

struct EstateDetailUIModel {
    let estateId: String?
    let category: String?
    let title: String?
    let introduction: String?
    let reservationPrice: Int?
    let thumbnails: [String]?
    let description: String?
    let deposit: Int?
    let monthlyRent: Int?
    let builtYear: String?
    let maintenanceFee: Int?
    let area: Double?
    let parkingCount: Int?
    let floors: Int?
    let options: EstateOptionsUIModel?
    let geolocation: GeolocationUIModel?
    let creator: EstateCreatorUIModel?
    let isLiked: Bool?
    let isReserved: Bool?
    let likeCount: Int?
    let isSafeEstate: Bool?
    let isRecommended: Bool?
    let comments: [EstateCommentUIModel]?
    let createdAt: String?
    let updatedAt: String?
}

struct EstateOptionsUIModel {
    let option1: String?
    let option2: String?
    let option3: String?
    let option4: String?
    let option5: String?
    let option6: String?
    let option7: String?
    let option8: String?
    let option9: String?
    let option10: String?
}

struct GeolocationUIModel {
    let longitude: Double?
    let latitude: Double?
}

struct EstateCreatorUIModel {
    let userId: String?
    let nick: String?
    let introduction: String?
    let profileImage: String?
}

struct EstateCommentUIModel {
    let commentId: String?
    let content: String?
    let createdAt: String?
    let creator: EstateCreatorUIModel?
    let replies: [EstateCommentUIModel]?
}

// MARK: - DTO to UIModel Extensions

extension EstateDetailResponseDTO {
    func toUIModel() -> EstateDetailUIModel {
        return EstateDetailUIModel(
            estateId: self.estateId,
            category: self.category,
            title: self.title,
            introduction: self.introduction,
            reservationPrice: self.reservationPrice,
            thumbnails: self.thumbnails,
            description: self.description,
            deposit: self.deposit,
            monthlyRent: self.monthlyRent,
            builtYear: self.builtYear,
            maintenanceFee: self.maintenanceFee,
            area: self.area,
            parkingCount: self.parkingCount,
            floors: self.floors,
            options: self.options?.toUIModel(),
            geolocation: self.geolocation?.toUIModel(),
            creator: self.creator?.toUIModel(),
            isLiked: self.isLiked,
            isReserved: self.isReserved,
            likeCount: self.likeCount,
            isSafeEstate: self.isSafeEstate,
            isRecommended: self.isRecommended,
            comments: self.comments?.map { $0.toUIModel() },
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}

extension EstateDetailUIModel {
    func updating(isLiked: Bool?) -> EstateDetailUIModel {
        return EstateDetailUIModel(
            estateId: estateId,
            category: category,
            title: title,
            introduction: introduction,
            reservationPrice: reservationPrice,
            thumbnails: thumbnails,
            description: description,
            deposit: deposit,
            monthlyRent: monthlyRent,
            builtYear: builtYear,
            maintenanceFee: maintenanceFee,
            area: area,
            parkingCount: parkingCount,
            floors: floors,
            options: options,
            geolocation: geolocation,
            creator: creator,
            isLiked: isLiked,
            isReserved: isReserved,
            likeCount: likeCount,
            isSafeEstate: isSafeEstate,
            isRecommended: isRecommended,
            comments: comments,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension EstateOptionsDTO {
    func toUIModel() -> EstateOptionsUIModel {
        return EstateOptionsUIModel(
            option1: self.option1,
            option2: self.option2,
            option3: self.option3,
            option4: self.option4,
            option5: self.option5,
            option6: self.option6,
            option7: self.option7,
            option8: self.option8,
            option9: self.option9,
            option10: self.option10
        )
    }
}

extension GeolocationDTO {
    func toUIModel() -> GeolocationUIModel {
        return GeolocationUIModel(
            longitude: self.longitude,
            latitude: self.latitude
        )
    }
}

extension EstateCreatorDTO {
    func toUIModel() -> EstateCreatorUIModel {
        return EstateCreatorUIModel(
            userId: self.userId,
            nick: self.nick,
            introduction: self.introduction,
            profileImage: self.profileImage
        )
    }
}

extension EstateCommentDTO {
    func toUIModel() -> EstateCommentUIModel {
        return EstateCommentUIModel(
            commentId: self.commentId,
            content: self.content,
            createdAt: self.createdAt,
            creator: self.creator?.toUIModel(),
            replies: self.replies?.map { $0.toUIModel() }
        )
    }
}
