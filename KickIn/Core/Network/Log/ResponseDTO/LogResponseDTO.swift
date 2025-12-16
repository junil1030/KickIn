//
//  LogResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

// MARK: - Response DTO
struct LogsResponseDTO: Decodable {
    let count: Int?
    let logs: [LogDTO]?
}

// MARK: - Log DTO
struct LogDTO: Decodable {
    let date: String?
    let name: String?
    let method: String?
    let routePath: String?
    let body: String?
    let contentType: String?
    let statusCode: String?
    
    enum CodingKeys: String, CodingKey {
        case date
        case name
        case method
        case routePath = "route_path"
        case body
        case contentType
        case statusCode = "status_code"
    }
}
