//
//  ChatRouter.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire

enum ChatRouter: APIRouter {
    case createOrGetChatRoom(CreateChatRoomRequestDTO)
    case getChatRooms
    case sendMessage(roomId: String, SendMessageRequestDTO)
    case getChatMessages(roomId: String, next: String?)
    case uploadFiles(roomId: String)

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid Chat URL")
        }
    }

    var method: HTTPMethod {
        return switch self {
        case .createOrGetChatRoom: .post
        case .getChatRooms: .get
        case .sendMessage: .post
        case .getChatMessages: .get
        case .uploadFiles: .post
        }
    }

    var path: String {
        return switch self {
        case .createOrGetChatRoom: "/chats"
        case .getChatRooms: "/chats"
        case .sendMessage(let roomId, _): "/chats/\(roomId)"
        case .getChatMessages(let roomId, _): "/chats/\(roomId)"
        case .uploadFiles(let roomId): "/chats/\(roomId)/files"
        }
    }

    var headers: HTTPHeaders {
        switch self {
        case .createOrGetChatRoom, .getChatRooms, .sendMessage, .getChatMessages:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        case .uploadFiles:
            let headerTypes: [APIHeader] = [.multipartFormData, .apiKey]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: self.baseURL.appendingPathComponent(self.path).absoluteString)!

        // Add query parameters for GET requests
        switch self {
        case .getChatMessages(_, let next):
            if let next = next {
                components.queryItems = [URLQueryItem(name: "next", value: next)]
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
        case .createOrGetChatRoom(let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .getChatRooms, .getChatMessages:
            break
        case .sendMessage(_, let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .uploadFiles:
            // Multipart form data will be handled by NetworkService
            break
        }

        return request
    }
}
