//
//  UserRouter.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire

enum UserRouter: APIRouter {
    case refreshToken(token: String)
    case emailValidation(email: String)
    case join(JoinRequestDTO)
    case login(LoginRequestDTO)
    case kakaoLogin(KakaoLoginRequestDTO)
    case appleLogin(AppleLoginRequestDTO)
    case logout
    case updateDeviceToken(DeviceTokenRequestDTO)
    case userProfile(userId: String)
    case myProfile
    case updateMyProfile(UpdateProfileRequestDTO)
    case uploadProfileImage
    case searchUsers(nick: String)

    var baseURL: URL {
        if let url = URL(string: APIConfig.baseURL) {
            return url
        } else {
            assert(false, "is not valid User URL")
        }
    }

    var method: HTTPMethod {
        return switch self {
        case .refreshToken: .get
        case .emailValidation: .post
        case .join: .post
        case .login: .post
        case .kakaoLogin: .post
        case .appleLogin: .post
        case .logout: .post
        case .updateDeviceToken: .put
        case .userProfile: .get
        case .myProfile: .get
        case .updateMyProfile: .put
        case .uploadProfileImage: .post
        case .searchUsers: .get
        }
    }

    var path: String {
        return switch self {
        case .refreshToken: "/auth/refresh"
        case .emailValidation: "/users/validation/email"
        case .join: "/users/join"
        case .login: "/users/login"
        case .kakaoLogin: "/users/login/kakao"
        case .appleLogin: "/users/login/apple"
        case .logout: "/users/logout"
        case .updateDeviceToken: "/users/deviceToken"
        case .userProfile(let userId): "/users/\(userId)/profile"
        case .myProfile: "/users/me/profile"
        case .updateMyProfile: "/users/me/profile"
        case .uploadProfileImage: "/users/profile/image"
        case .searchUsers: "/users/search"
        }
    }

    var headers: HTTPHeaders {
        switch self {
        case .refreshToken(let token):
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey, .refreshToken(token)]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        case .uploadProfileImage:
            let headerTypes: [APIHeader] = [.apiKey, .multipartFormData]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        case .emailValidation, .join, .login, .kakaoLogin, .appleLogin, .logout, .updateDeviceToken, .userProfile, .myProfile, .updateMyProfile, .searchUsers:
            let headerTypes: [APIHeader] = [.applicationJSON, .apiKey]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: self.baseURL.appendingPathComponent(self.path).absoluteString)!

        // Add query parameters for GET requests
        switch self {
        case .searchUsers(let nick):
            components.queryItems = [URLQueryItem(name: "nick", value: nick)]
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
        case .emailValidation(let email):
            let requestDTO = EmailValidationRequestDTO(email: email)
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .join(let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .login(let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .kakaoLogin(let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .appleLogin(let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .updateDeviceToken(let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        case .updateMyProfile(let requestDTO):
            request.httpBody = try? JSONEncoder().encode(requestDTO)
        default:
            break
        }

        return request
    }
}
