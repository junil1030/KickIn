//
//  CommunityPostRouter.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire

enum CommunityPostRouter: APIRouter {
    case uploadFiles
    case createPost(CreatePostRequestDTO)
    case getPostsByGeolocation(category: String?, longitude: String?, latitude: String?, maxDistance: String?, limit: Int?, next: String?, orderBy: String?)
    case searchPosts(title: String)
    case getPostDetail(postId: String)
    case updatePost(postId: String, UpdatePostRequestDTO)
    case deletePost(postId: String)
    case likePost(postId: String, PostLikeRequestDTO)
    case getUserPosts(userId: String, category: String?, limit: Int?, next: String?)
    case getMyLikedPosts(category: String?, limit: String?, next: String?)

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid CommunityPost URL")
        }
    }

    var method: HTTPMethod {
        return switch self {
        case .uploadFiles: .post
        case .createPost: .post
        case .getPostsByGeolocation: .get
        case .searchPosts: .get
        case .getPostDetail: .get
        case .updatePost: .put
        case .deletePost: .delete
        case .likePost: .post
        case .getUserPosts: .get
        case .getMyLikedPosts: .get
        }
    }

    var path: String {
        return switch self {
        case .uploadFiles: "/posts/files"
        case .createPost: "/post"
        case .getPostsByGeolocation: "/posts/geolocation"
        case .searchPosts: "/posts/search"
        case .getPostDetail(let postId): "/posts/\(postId)"
        case .updatePost(let postId, _): "/posts/\(postId)"
        case .deletePost(let postId): "/posts/\(postId)"
        case .likePost(let postId, _): "/posts/\(postId)/like"
        case .getUserPosts(let userId, _, _, _): "/posts/users/\(userId)"
        case .getMyLikedPosts: "/posts/likes/me"
        }
    }

    var headers: HTTPHeaders {
        switch self {
        case .uploadFiles:
            let headerTypes: [APIHeader] = [.multipartFormData, .apiKey]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        case .createPost, .getPostsByGeolocation, .searchPosts, .getPostDetail, .updatePost, .deletePost, .likePost, .getUserPosts, .getMyLikedPosts:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: self.baseURL.appendingPathComponent(self.path).absoluteString)!

        // Add query parameters for GET requests
        switch self {
        case .getPostsByGeolocation(let category, let longitude, let latitude, let maxDistance, let limit, let next, let orderBy):
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
                queryItems.append(URLQueryItem(name: "maxDistance", value: maxDistance))
            }
            if let limit = limit {
                queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            if let next = next {
                queryItems.append(URLQueryItem(name: "next", value: next))
            }
            if let orderBy = orderBy {
                queryItems.append(URLQueryItem(name: "order_by", value: orderBy))
            }
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
        case .searchPosts(let title):
            components.queryItems = [URLQueryItem(name: "title", value: title)]
        case .getUserPosts(_, let category, let limit, let next):
            var queryItems: [URLQueryItem] = []
            if let category = category {
                queryItems.append(URLQueryItem(name: "category", value: category))
            }
            if let limit = limit {
                queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            if let next = next {
                queryItems.append(URLQueryItem(name: "next", value: next))
            }
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
        case .getMyLikedPosts(let category, let limit, let next):
            var queryItems: [URLQueryItem] = []
            if let category = category {
                queryItems.append(URLQueryItem(name: "category", value: category))
            }
            if let limit = limit {
                queryItems.append(URLQueryItem(name: "limit", value: limit))
            }
            if let next = next {
                queryItems.append(URLQueryItem(name: "next", value: next))
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

        // Add request body for POST/PUT requests
        switch self {
        case .uploadFiles:
            // Multipart form data will be handled by NetworkService
            break
        case .createPost(let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .updatePost(_, let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .likePost(_, let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        default:
            break
        }

        return request
    }
}
