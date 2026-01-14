//
//  KickInAuthenticator.swift
//  KickIn
//
//  Created by 서준일 on 1/14/26.
//

import Foundation
import Alamofire

final class KickInAuthenticator: Authenticator {
    func refresh(_ credential: KickInAuthenticationCredential, for session: Alamofire.Session, completion: @escaping @Sendable (Result<KickInAuthenticationCredential, any Error>) -> Void) {
        return
    }
    
    func apply(_ credential: KickInAuthenticationCredential, to urlRequest: inout URLRequest) {
        return
    }
    
    func didRequest(_ urlRequest: URLRequest, with response: HTTPURLResponse, failDueToAuthenticationError error: any Error) -> Bool {
        return true
    }
    
    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: KickInAuthenticationCredential) -> Bool {
        return true
    }
}
