//
//  BannerUIModel.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation

struct BannerUIModel: Identifiable, Hashable {
    let id = UUID()
    let name: String?
    let imageUrl: String?
    let payloadType: BannerPayloadType?
    let payloadValue: String?

    var webViewURL: URL? {
        guard payloadType == .webview, let payloadValue else { return nil }

        if payloadValue.hasPrefix("http") {
            return URL(string: payloadValue)
        }

        return URL(string: APIConfig.socketURL + payloadValue)
    }
}

extension BannerItemDTO {
    func toUIModel() -> BannerUIModel {
        return BannerUIModel(
            name: name,
            imageUrl: imageUrl,
            payloadType: payload?.type,
            payloadValue: payload?.value
        )
    }
}
