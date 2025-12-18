//
//  Config.swift
//  KickIn
//
//  Created by 서준일 on 12/18/25.
//

import Foundation

enum Config {
    private static let info = Bundle.main.infoDictionary
    
    static let kakaoNativeAppKey: String = {
        guard let appkey = info?["kakao_native_app_key"] as? String else {
            fatalError("required api_key")
        }
        return appkey
    }()
}
