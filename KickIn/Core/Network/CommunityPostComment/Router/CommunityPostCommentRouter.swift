//
//  CommunityPostCommentRouter.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire

enum CommunityPostCommentRouter: APIRouter {
    case createComment(postId: String, PostCommentRequestDTO)
    case updateComment(postId: String, commentId: String, UpdatePostCommentRequestDTO)
    case deleteComment(postId: String, commentId: String)

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid CommunityPostComment URL")
        }
    }

    var method: HTTPMethod {
        return switch self {
        case .createComment: .post
        case .updateComment: .put
        case .deleteComment: .delete
        }
    }

    var path: String {
        return switch self {
        case .createComment(let postId, _): "/posts/\(postId)/comments"
        case .updateComment(let postId, let commentId, _): "/posts/\(postId)/comments/\(commentId)"
        case .deleteComment(let postId, let commentId): "/posts/\(postId)/comments/\(commentId)"
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

        // Add request body for POST/PUT requests
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
