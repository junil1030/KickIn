//
//  NetworkError.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

enum NetworkError: Error {
    case unauthorized
    case forbidden
    case notFound
    case badRequest(message: String?)
    case serverError
    case decodingError
    case networkFailure(Error)
    case invalidURL
    case noData
    case unknown

    var localizedDescription: String {
        switch self {
        case .unauthorized:
            return "인증이 필요합니다."
        case .forbidden:
            return "접근 권한이 없습니다."
        case .notFound:
            return "요청한 리소스를 찾을 수 없습니다."
        case .badRequest(let message):
            return message ?? "잘못된 요청입니다."
        case .serverError:
            return "서버 오류가 발생했습니다."
        case .decodingError:
            return "데이터 파싱 오류가 발생했습니다."
        case .networkFailure(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .noData:
            return "데이터가 없습니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
