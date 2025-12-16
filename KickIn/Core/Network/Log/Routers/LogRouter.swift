//
//  LogRouter.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire

enum LogRouter: APIRouter {
    case log
    
    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid Log URL")
        }
    }
    
    var method: HTTPMethod {
        return switch self {
        case .log: .get
        }
    }
    
    var path: String {
        return switch self {
        case .log: "/log"
        }
    }
    
    var headers: HTTPHeaders {
        switch self {
        default:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey,]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: self.baseURL.appendingPathComponent(self.path).absoluteString)!
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.method = self.method
        request.headers = self.headers
        return request
    }
    
    
}
