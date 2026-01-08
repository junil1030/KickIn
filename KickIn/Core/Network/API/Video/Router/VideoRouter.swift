//
//  VideoRouter.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation
import Alamofire

enum VideoRouter: APIRouter {
    case getVideos(next: String?, limit: Int?)
    case getStream(videoId: String)
    case likeVideo(videoId: String, VideoLikeRequestDTO)

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid Video URL")
        }
    }

    var method: HTTPMethod {
        return switch self {
        case .getVideos: .get
        case .getStream: .get
        case .likeVideo: .post
        }
    }

    var path: String {
        return switch self {
        case .getVideos: "/videos"
        case .getStream(let videoId): "/videos/\(videoId)/stream"
        case .likeVideo(let videoId, _): "/videos/\(videoId)/like"
        }
    }

    var headers: HTTPHeaders {
        switch self {
        case .getVideos, .getStream, .likeVideo:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: self.baseURL.appendingPathComponent(self.path).absoluteString)!

        // Add query parameters for GET requests
        switch self {
        case .getVideos(let next, let limit):
            var queryItems: [URLQueryItem] = []
            if let next = next {
                queryItems.append(URLQueryItem(name: "next", value: next))
            }
            if let limit = limit {
                queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
        case .getStream, .likeVideo:
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
        case .likeVideo(_, let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .getVideos, .getStream:
            break
        }

        return request
    }
}
