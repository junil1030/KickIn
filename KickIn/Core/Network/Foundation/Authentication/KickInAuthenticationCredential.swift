//
//  KickInAuthenticationCredential.swift
//  KickIn
//
//  Created by 서준일 on 1/14/26.
//

import Foundation
import Alamofire

struct KickInAuthenticationCredential: AuthenticationCredential, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiration: Date
    
    var requiresRefresh: Bool { Date(timeIntervalSinceNow: 60 * 5) > expiration }
}
