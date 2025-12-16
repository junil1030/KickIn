//
//  EstateCommentRouter.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire

enum EstateCommentRouter: APIRouter {
    case createComment(estateId: String, EstateCommentRequestDTO)
    case updateComment(estateId: String, commentId: String, UpdateEstateCommentRequestDTO)
    case deleteComment(estateId: String, commentId: String)

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid EstateComment URL")
        }
    }

    var method: HTTPMethod {
        return switch self {
        case .createComment: .post
        case .updateComment: .patch
        case .deleteComment: .delete
        }
    }

    var path: String {
        return switch self {
        case .createComment(let estateId, _): "/estates/\(estateId)/comments"
        case .updateComment(let estateId, let commentId, _): "/estates/\(estateId)/comments/\(commentId)"
        case .deleteComment(let estateId, let commentId): "/estates/\(estateId)/comments/\(commentId)"
        }
    }

    var headers: HTTPHeaders {
        switch self {
        case .createComment, .updateComment, .deleteComment:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = self.baseURL.appendingPathComponent(self.path)
        var request = URLRequest(url: url)
        request.method = self.method
        request.headers = self.headers

        // Add request body for POST/PATCH requests
        switch self {
        case .createComment(_, let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .updateComment(_, _, let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .deleteComment:
            break
        }

        return request
    }
}
