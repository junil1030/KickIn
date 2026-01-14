//
//  KickInCredential.swift
//  KickIn
//
//  Created by 서준일 on 1/14/26.
//

import Foundation
import Alamofire

struct KickInCredential: AuthenticationCredential {
    let accessToken: String
    let refreshToken: String
    let expiration: Date
    
    var requiresRefresh: Bool { Date(timeIntervalSinceNow: 60 * 5) > expiration }
}
