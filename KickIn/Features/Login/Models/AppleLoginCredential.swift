//
//  AppleLoginCredential.swift
//  KickIn
//
//  Created by 서준일 on 12/17/25.
//

import Foundation
import AuthenticationServices

struct AppleLoginCredential {
    let identityToken: String
    let user: String
    let email: String?
    let fullName: PersonNameComponents?

    init?(from credential: ASAuthorizationAppleIDCredential) {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            return nil
        }

        self.identityToken = tokenString
        self.user = credential.user
        self.email = credential.email
        self.fullName = credential.fullName
    }
}
