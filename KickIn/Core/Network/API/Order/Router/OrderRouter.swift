//
//  OrderRouter.swift
//  KickIn
//
//  Created by 서준일 on 01/07/26.
//

import Foundation
import Alamofire

enum OrderRouter: APIRouter {
    case createOrder(CreateOrderRequestDTO)
    case orders

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid Order URL")
        }
    }

    var method: HTTPMethod {
        return switch self {
        case .createOrder: .post
        case .orders: .get
        }
    }

    var path: String {
        return switch self {
        case .createOrder, .orders: "/orders"
        }
    }

    var headers: HTTPHeaders {
        switch self {
        case .createOrder, .orders:
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

        switch self {
        case .createOrder(let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .orders:
            break
        }

        return request
    }
}
