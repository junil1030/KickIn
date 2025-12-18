//
//  APIHeader.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire

enum APIHeader {
    case apiKey
    case applicationJSON
    case refreshToken(String)
    case multipartFormData
}

extension APIHeader {
    var httpHeader: HTTPHeader {
        switch self {
        case .apiKey:
            return HTTPHeader(name: "SeSACKey", value: APIConfig.apikey)

        case .applicationJSON:
            return HTTPHeader(name: "Content-Type", value: "application/json")

        case .refreshToken(let token):
            return HTTPHeader(name: "RefreshToken", value: token)

        case .multipartFormData:
            // Note: Actual boundary will be set by Alamofire's upload(multipartFormData:)
            return HTTPHeader(name: "Content-Type", value: "multipart/form-data")
        }
    }
}
