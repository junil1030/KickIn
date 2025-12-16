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
}

extension APIHeader {
    var httpHeader: HTTPHeader {
        switch self {
        case .apiKey:
            return HTTPHeader(name: "SeSACKey", value: APIConfig.apikey)
            
        case .applicationJSON:
            return HTTPHeader(name: "Content-Type", value: "applicationJSON")
        }
    }
}
