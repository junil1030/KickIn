//
//  APIConfig.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

enum APIConfig {
    private static let info = Bundle.main.infoDictionary
    
    private static let domain: String = {
        guard let domain = info?["domain"] as? String else {
            fatalError("required base_url")
        }
        return domain
    }()

    static let apikey: String = {
        guard let apiKey = info?["api_key"] as? String else {
            fatalError("required api_key")
        }
        return apiKey
    }()
    
    static let baseURL: String = "http://" + domain + "/v1"
    static let socketURL: String = "http://" + domain
}
