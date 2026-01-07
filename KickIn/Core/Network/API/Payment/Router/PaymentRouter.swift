//
//  PaymentRouter.swift
//  KickIn
//
//  Created by 서준일 on 01/07/26.
//

import Foundation
import Alamofire

enum PaymentRouter: APIRouter {
    case validateReceipt(PaymentValidationRequestDTO)
    case receipt(orderCode: String)

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid Payment URL")
        }
    }

    var method: HTTPMethod {
        return switch self {
        case .validateReceipt: .post
        case .receipt: .get
        }
    }

    var path: String {
        return switch self {
        case .validateReceipt: "/payments/validation"
        case .receipt(let orderCode): "/payments/\(orderCode)"
        }
    }

    var headers: HTTPHeaders {
        switch self {
        case .validateReceipt, .receipt:
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
        case .validateReceipt(let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .receipt:
            break
        }

        return request
    }
}
