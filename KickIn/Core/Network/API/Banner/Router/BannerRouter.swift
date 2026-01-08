//
//  BannerRouter.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation
import Alamofire

enum BannerRouter: APIRouter {
    case mainBanners

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid Banner URL")
        }
    }

    var method: HTTPMethod {
        return switch self {
        case .mainBanners: .get
        }
    }

    var path: String {
        return switch self {
        case .mainBanners: "/banners/main" 
        }
    }

    var headers: HTTPHeaders {
        switch self {
        case .mainBanners:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }

    func asURLRequest() throws -> URLRequest {
        let components = URLComponents(string: self.baseURL.appendingPathComponent(self.path).absoluteString)!

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.method = self.method
        request.headers = self.headers

        return request
    }
}
