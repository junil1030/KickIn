//
//  EstateRouter.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire

enum EstateRouter: APIRouter {
    case estateDetail(estateId: String)
    case likeEstate(estateId: String, EstateLikeRequestDTO)
    case myLikes(category: String?, next: String?, limit: String?)
    case geolocation(category: String?, longitude: String?, latitude: String?, maxDistance: Int?)
    case todayEstates
    case hotEstates
    case similarEstates
    case todayTopic

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid Estate URL")
        }
    }

    var method: HTTPMethod {
        return switch self {
        case .estateDetail: .get
        case .likeEstate: .post
        case .myLikes: .get
        case .geolocation: .get
        case .todayEstates: .get
        case .hotEstates: .get
        case .similarEstates: .get
        case .todayTopic: .get
        }
    }

    var path: String {
        return switch self {
        case .estateDetail(let estateId): "/estates/\(estateId)"
        case .likeEstate(let estateId, _): "/estates/\(estateId)/like"
        case .myLikes: "/estates/likes/me"
        case .geolocation: "/estates/geolocation"
        case .todayEstates: "/estates/today-estates"
        case .hotEstates: "/estates/hot-estates"
        case .similarEstates: "/estates/similar-estates"
        case .todayTopic: "/estates/today-topic"
        }
    }

    var headers: HTTPHeaders {
        switch self {
        case .estateDetail, .likeEstate, .myLikes, .geolocation, .todayEstates, .hotEstates, .similarEstates, .todayTopic:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: self.baseURL.appendingPathComponent(self.path).absoluteString)!

        // Add query parameters for GET requests
        switch self {
        case .myLikes(let category, let next, let limit):
            var queryItems: [URLQueryItem] = []
            if let category = category {
                queryItems.append(URLQueryItem(name: "category", value: category))
            }
            if let next = next {
                queryItems.append(URLQueryItem(name: "next", value: next))
            }
            if let limit = limit {
                queryItems.append(URLQueryItem(name: "limit", value: limit))
            }
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
        case .geolocation(let category, let longitude, let latitude, let maxDistance):
            var queryItems: [URLQueryItem] = []
            if let category = category {
                queryItems.append(URLQueryItem(name: "category", value: category))
            }
            if let longitude = longitude {
                queryItems.append(URLQueryItem(name: "longitude", value: longitude))
            }
            if let latitude = latitude {
                queryItems.append(URLQueryItem(name: "latitude", value: latitude))
            }
            if let maxDistance = maxDistance {
                queryItems.append(URLQueryItem(name: "maxDistance", value: String(maxDistance)))
            }
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
        default:
            break
        }

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.method = self.method
        request.headers = self.headers

        // Add request body for POST requests
        switch self {
        case .likeEstate(_, let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        default:
            break
        }

        return request
    }
}
