//
//  String+Extension.swift
//  KickIn
//
//  Created by 서준일 on 12/22/25.
//

import Foundation

extension String {
    var thumbnailURL: URL? {
        let urlString = APIConfig.baseURL + self
        return URL(string: urlString)
    }
}
